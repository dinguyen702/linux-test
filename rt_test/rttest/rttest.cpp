#include <stdlib.h>
#include <stdio.h>
#include <time.h>
#include <sched.h>
#include <sys/mman.h>
#include <string.h>

#define MY_PRIORITY (49)

#define MAX_SAFE_STACK (8*1024)

#define NSEC_PER_SEC (1000000000)

void stack_prefault(void)
{
	unsigned char dummy[MAX_SAFE_STACK];
	memset(dummy, 0, MAX_SAFE_STACK);
	return;
}

int main(int argc, char **argv)
{
	struct timespec t;
	struct sched_param param;
	int interval = 50000; 

	param.sched_priority = MY_PRIORITY;
	if (sched_setscheduler(0,SCHED_FIFO,&param) == -1) {
		perror("sched_setscheduler failed");
		exit(-1);
	}

	if (mlockall(MCL_CURRENT|MCL_FUTURE) == -1) {
		perror("mlockall failed");
		exit(-2);
	}

	stack_prefault();

	clock_gettime(CLOCK_MONOTONIC, &t);
	t.tv_sec++;

	while (1) {
		clock_nanosleep(CLOCK_MONOTONIC, TIMER_ABSTIME, &t, NULL);

		t.tv_nsec += interval;

		while (t.tv_nsec >= NSEC_PER_SEC) {
			t.tv_nsec -= NSEC_PER_SEC;
			t.tv_sec++;
		}
	}
}
