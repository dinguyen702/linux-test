#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdarg.h>
#include <unistd.h>
#include <fcntl.h>
#include <getopt.h>
#include <pthread.h>
#include <signal.h>
#include <sched.h>
#include <string.h>
#include <time.h>
#include <errno.h>
#include <limits.h>
#include <linux/unistd.h>

#include <sys/prctl.h>
#include <sys/stat.h>
#include <sys/sysinfo.h>
#include <sys/types.h>
#include <sys/time.h>
#include <sys/resource.h>
#include <sys/utsname.h>
#include <sys/mman.h>
#include <cmath>

#include <algorithm>
#include <vector>
#include <map>

#include "OnlineStats.h"
#include "QuantileEstimator.h"

#define MY_PRIORITY 80
#define MAX_SAFE_STACK (8*1024)


class Histogram {
public:
	int buckets;
	size_t sz;
	int *hist;
        int overflow;
	int underflow;
	Histogram(int n)
	{
		buckets = n*2;
		sz = sizeof(int) * n * 2;	
		hist = (int *) malloc ( sz );
		memset(hist, 0, sz);
		overflow=0;
		underflow=0;
	}

	void
	Acc(int val)
	{
            int ndx = val + buckets/2;
            if (ndx >= buckets) {
		overflow++;
		return;
	    }
	    if (ndx < 0) {
	   	underflow++;
	    }
	    hist[ndx]++;
	}

	~Histogram()
	{
		free(hist);
	}
};


class timerctx {
public:
	int clksrc; // 0 for monotonic, 1 for realtime
	int iterations;
	int64_t interval;
	int priority;
	int threadid;
	QuantileEstimator *pm_q5;
	QuantileEstimator *pm_q50;
	QuantileEstimator *pm_q95;
	QuantileEstimator *pm_q99;
	OnlineStats *pstats;
	Histogram *phist;
	timerctx() 
	{
		pm_q5 = new QuantileEstimator(.05);
		pm_q50 = new QuantileEstimator(.50);
		pm_q95= new QuantileEstimator(.95);
		pm_q99 = new QuantileEstimator(.99);
	 	pstats = new OnlineStats();		
		phist = new Histogram(1000);
	}
};

void tthread(void *ctx);

static int latency_target_fd = -1;
static int32_t latency_target_value = 0;
static volatile int exitf=0;

void stack_prefault(void)
{
	unsigned char dummy[MAX_SAFE_STACK];
	memset(dummy, 0, MAX_SAFE_STACK);
	return;
}
int check_privs(void)
{
	int policy = sched_getscheduler(0);
	struct sched_param param, old_param;

	/* if we're already running a realtime scheduler
	 * then we *should* be able to change things later
	 */
	if (policy == SCHED_FIFO || policy == SCHED_RR)
		return 0;

	/* first get the current parameters */
	if (sched_getparam(0, &old_param)) {
		fprintf(stderr, "unable to get scheduler parameters\n");
		return 1;
	}
	param = old_param;

	/* try to change to SCHED_FIFO */
	param.sched_priority = 1;
	if (sched_setscheduler(0, SCHED_FIFO, &param)) {
		fprintf(stderr, "Unable to change scheduling policy!\n");
		fprintf(stderr, "either run as root or join realtime group\n");
		return 1;
	}

	/* we're good; change back and return success */
	return sched_setscheduler(0, policy, &old_param);
}

static void set_latency_target(void)
{
	struct stat s;
	int ret;

	if (stat("/dev/cpu_dma_latency", &s) == 0) {
		latency_target_fd = open("/dev/cpu_dma_latency", O_RDWR);
		if (latency_target_fd == -1)
			return;
		ret = write(latency_target_fd, &latency_target_value, 4);
		if (ret == 0) {
			printf("# error setting cpu_dma_latency to %d!: %s\n", latency_target_value, strerror(errno));
			close(latency_target_fd);
			return;
		}
		printf("# /dev/cpu_dma_latency set to %dus\n", latency_target_value);
	}
}

static int raise_soft_prio(int policy, const struct sched_param *param)
{
	int err;
	int policy_max;	/* max for scheduling policy such as SCHED_FIFO */
	int soft_max;
	int hard_max;
	int prio;
	struct rlimit rlim;

	prio = param->sched_priority;

	policy_max = sched_get_priority_max(policy);
	if (policy_max == -1) {
		err = errno;
		printf("WARN: no such policy\n");
		exit(1);
	}

	err = getrlimit(RLIMIT_RTPRIO, &rlim);
	if (err) {
		err = errno;
		printf("WARN: getrlimit failed, %d, %s\n", err, strerror(err));
		exit(1);
	}

	soft_max = (rlim.rlim_cur == RLIM_INFINITY) ? policy_max : rlim.rlim_cur;
	hard_max = (rlim.rlim_max == RLIM_INFINITY) ? policy_max : rlim.rlim_max;

	if (prio > soft_max && prio <= hard_max) {
		rlim.rlim_cur = prio;
		err = setrlimit(RLIMIT_RTPRIO, &rlim);
		if (err) {
			err = errno;
			printf("WARN: setrlimit failed %d, %s\n", err,
				strerror(err));
			exit(1);
	
			/* return err; */
		}
	} else {
		err = -1;
	}

	return err;
}

static int setscheduler(pid_t pid, int policy, const struct sched_param *param)
{
	int err = 0;

try_again:
	err = sched_setscheduler(pid, policy, param);
	if (err) {
		err = errno;
		if (err == EPERM) {
			int err1;
			err1 = raise_soft_prio(policy, param);
			if (!err1) goto try_again;
		}
	}

	return err;
}
static 
int 
clocksources[] = {
	CLOCK_MONOTONIC,
	CLOCK_REALTIME,
};

#define NSEC_PER_SEC 1000000000

static 
inline 
int64_t 
calcdiff(
	struct timespec t1, 
	struct timespec t2)
{
	int64_t	diff;
	diff = NSEC_PER_SEC * (int64_t)((int) t1.tv_sec - (int) t2.tv_sec);
	diff += ((int) t1.tv_nsec - (int) t2.tv_nsec);
	return diff;
}

static inline int64_t
timens(struct timespec t1)
{
	int64_t tm = NSEC_PER_SEC * (int64_t)((int) t1.tv_sec );
	tm += t1.tv_nsec;
	return tm;
}

void *timerthread(void *ctx)
{
	timerctx *ptctx = (timerctx *) ctx;
	struct timespec next, now;
	int64_t diff;
	int ret;
        struct timespec req; 
	struct sched_param param;

	param.sched_priority = ptctx->priority;
	if (sched_setscheduler(0,SCHED_FIFO,&param) == -1) {
		perror("sched_setscheduler failed");
		exit(-1);
	}

	if (mlockall(MCL_CURRENT|MCL_FUTURE) == -1) {
		perror("mlockall failed");
		exit(-2);
	}

	stack_prefault();

        for (int i=0; i<ptctx->iterations; i++) {
		ret = clock_gettime(clocksources[ptctx->clksrc], (&now));
		if (ret != 0) {
			printf("clock_gettime failed %d, %s\n", ret,
				strerror(errno));
			exit(1);
		}
		req.tv_sec = 0;//now.tv_sec;
		req.tv_nsec = 100*(1000*1000);
		//ret = clock_nanosleep(clocksources[clksrc], TIMER_ABSTIME, &req, NULL);
		ret = clock_nanosleep(clocksources[ptctx->clksrc], 0, &req, NULL);
		if (ret != 0) {
			printf("clock_nanosleep failed %d\n", ret);
			exit(1);
		}

		ret = clock_gettime(clocksources[ptctx->clksrc], (&next));
		if (ret != 0) {
			printf("clock_gettime failed %d\n", ret);
			exit(1);
		}

		diff = calcdiff(next, now) ;

                int delta = (int)(diff-timens(req))/1000;
		ptctx->pm_q5->push(delta);
		ptctx->pm_q50->push(delta);
		ptctx->pm_q99->push(delta);
		ptctx->pm_q95->push(delta);

		ptctx->pstats->Push(delta);
		ptctx->phist->Acc(delta);

        	//printf("diff %lld, %lld\n", diff/1000, (diff-timens(req))/1000);
	}
	return NULL;
}

void *pmem;
void *psrc;
size_t memsize;


int main(void)
{
	pthread_t thread1[4];
	timerctx *pctx[4];

        pthread_t loadThread1;
        pthread_t loadThread2;

	int numthreads=4;

	int threadid=0;
	memsize = 2*1024*1024;
        psrc = malloc(memsize);
	pmem = malloc(memsize);
	if (check_privs()) {
		printf("must run as root, or sudo\n");
		exit(1);
	}	

	set_latency_target();

	if (mlockall(MCL_CURRENT|MCL_FUTURE) == -1) {
		perror("mlockall");
		exit(1);
	}

        pthread_create(&loadThread1, NULL, (void * (*)(void *) ) &tthread,
			NULL);

        pthread_create(&loadThread2, NULL, (void * (*)(void *) ) &tthread,
			NULL);

	for (int i=0; i<numthreads; i++) {
		pctx[i] = new timerctx();
		pctx[i]->threadid = threadid;
		pctx[i]->clksrc = 1;
		pctx[i]->interval = 100*1000*1000; // 1 sec?
		pctx[i]->iterations = 5000;
		pctx[i]->priority = MY_PRIORITY;


		pthread_create(&thread1[i], NULL, (void * (*)(void *) ) &timerthread,
			pctx[i]);

		threadid++;
	}


	for (int i=0; i<numthreads; i++) {
		pthread_join(thread1[i], NULL);
		printf("thread %d, 5th Percentile %g\n", 
			pctx[i]->threadid,
			pctx[i]->pm_q5->quantile());
		printf("thread %d, 50th Percentile %g\n", 
			pctx[i]->threadid,
			pctx[i]->pm_q50->quantile());
		printf("thread %d, 95th Percentile %g\n", 
			pctx[i]->threadid,
			pctx[i]->pm_q95->quantile());
		printf("thread %d, 99th Percentile %g\n", 
			pctx[i]->threadid,
			pctx[i]->pm_q99->quantile());

        	printf("thread %d, Stddev %g, skew %g, Kurtosis %g\n", 
			pctx[i]->threadid,
			pctx[i]->pstats->StdDeviation(),
			pctx[i]->pstats->Skew(),
			pctx[i]->pstats->Kurtosis()); 
	}

        exitf=1;
        pthread_join(loadThread1, NULL);
        pthread_join(loadThread2, NULL);


	for (int i=0; i<pctx[0]->phist->buckets; i++) {
		printf("%d   %d, %d, %d, %d\n", 
			i,
			pctx[0]->phist->hist[i], 
			pctx[1]->phist->hist[i], 
			pctx[2]->phist->hist[i], 
			pctx[3]->phist->hist[i]);
	}
	printf("over %d, %d, %d, %d\n", 
		pctx[0]->phist->overflow, 
		pctx[1]->phist->overflow, 
		pctx[2]->phist->overflow, 
		pctx[3]->phist->overflow);

	printf("under %d, %d, %d, %d\n", 
		pctx[0]->phist->underflow, 
		pctx[1]->phist->underflow, 
		pctx[2]->phist->underflow, 
		pctx[3]->phist->underflow);

	exit(0);
}

void tthread(void *ctx)
{
#if 0
        struct timespec req; 
	printf("thread\n");

        while (exitf == 0) {
		memset( pmem, 0, memsize);
		memcpy( pmem, psrc, memsize);
	        req.tv_sec = 0;
                req.tv_nsec = (rand() % 10) * 1000;
		clock_nanosleep(CLOCK_REALTIME, 0, &req, NULL);
	}

        printf("exiting thread!\n");
#endif
	pthread_exit(0);
}


