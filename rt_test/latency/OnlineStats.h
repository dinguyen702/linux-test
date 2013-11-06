/*
    OnlineStats and Stats classes for computing interesting statistics. 

    OnlineStats is the one you want, it's been tested although I have no 
    unit tests for it (yet). OnlineStats is useful since it does not 
    allocate and maintain a vector of data for each sample as it's pushed, 
    yet maintains accurate estimations of statistical data as the data is 
    accumulated. Very useful for "Online", rolling statistical computation 
    and not continuing to allocate memory. 

    Based on
    http://en.wikipedia.org/wiki/Standard_deviation#Definition_of_population_values

    Stats is a simple minded statistical computation class that sorts and
    iterates through the samples
    (yes, that's ugly for large data sets, but useful for verifying the
    OnlineStats class). 

    Note that Boost has an algorithm for computing online statistics,
    but Boost can consume more than expected amount of load image space, 
    and can have unexpected performance impacts. Plus I like to understand
    what the code is doing, and what better to do that than rip it yourself. :)

    Usage....

    OnlineStats *pstats = new OnlineStats();

    for ( <some number of iterations ....> )  {

        pstats->Push ( yourData );

    }

    stddev = pstats->StdDeviation();
    skew   = pstats->Skew();

    .....
                     

    Vince Bridgers, provided for Altera's use
    vbridgers2013@gmail.com

class OnlineStats {
private:
    ....

public:

    // ctor
    OnlineStats();
    
    // zero the stats, start over
    void
    ZeroStats(void);

    // pushes a sample, returns the current number of samples
    long long
    Push(double x);

    // returns the current number of samples
    long long
    Values(void);

    // returns the current mean
    double
    Mean(void);

    // returns the current variance
    double
    Variance(void);

    // returns the current Standard Deviation
    double
    StdDeviation(void);

    // returns current Skew
    double
    Skew(void);
        
    // returns current Kurtosis
    double
    Kurtosis(void);

    // returns max, as useless as that might be
    double 
    Max(void);

    // returns min, as useless as that might be
    double
    Min(void);
};

 
*/



#pragma once
#ifndef __STATS_H__
#define __STATS_H__

class OnlineStats {
private:
    // Number of samples comprehended
    long long   m_samples;

    // The intermediate representation of moments. Final values computed at query time.
    double      m_mean;
    double      m_moment2;
    double      m_moment3;
    double      m_moment4;
    
    double      m_min;
    double      m_max;

public:

    OnlineStats()
    {
        ZeroStats();
    }
    
    void
    ZeroStats(void)
    {
        m_samples = 0;
        m_mean    = 0.0;
        m_moment2 = 0.0;
        m_moment3 = 0.0;
        m_moment4 = 0.0;
    }

    long long
    Push(double x)
    {
        double delta, delta_n, delta_n2, term1;

        long long n1    = m_samples;

        if (m_samples == 0) {
            m_min = x;
            m_max = x;
        } else {
            if (x < m_min) {
                m_min = x;
            }
            if (x > m_max) {
                m_max = x;
            }
        }

        m_samples++;
        delta           = x - m_mean;
        delta_n         = delta / m_samples;
        delta_n2        = delta_n * delta_n;
        term1           = delta * delta_n * n1;
        m_mean         += delta_n;
        m_moment4      += term1 * delta_n2 * (m_samples*m_samples - 3*m_samples + 3) + 6 * delta_n2 * m_moment2 - 4 * delta_n * m_moment3;
        m_moment3      += term1 * delta_n * (m_samples - 2) - 3 * delta_n * m_moment2;
        m_moment2      += term1;


        return m_samples;
    }

    long long
    Values(void)
    {
        return m_samples;
    }

    double
    Mean(void)
    {
        return m_mean;
    }

    double
    Variance(void)
    {
        return m_moment2/(m_samples-1.0);
    }

    double
    StdDeviation(void)
    {
        return std::sqrt( Variance() );
    }

    double
    Skew(void)
    {
        return std::sqrt(double(m_samples)) * m_moment3/ pow(m_moment2, 1.5);
    }
        
    double
    Kurtosis(void)
    {
        return double(m_samples)*m_moment4 / (m_moment2*m_moment2) - 3.0;
    }

    double 
    Max(void)
    {
        return m_max;
    }

    double
    Min(void)
    {
        return m_min;
    }
};

//
// The following class uses std:accumulate, which requires a different option
// for the x86 and arm compilers, so forget it for now since it's not used

#if 0
class Stats {
public:

    double  stddev;
    double  var;
    double  mean;
    double  skew;
    double  kurt;
    double  max;
    double  min;

    // the percentiles - from 0 through 100 in 1% increments. 0 is min, 
    // 100 is max, 50 is median;
    double  perc[100];

    double  samples;

    Stats(std::vector<double> v)
    {
        mean = std::accumulate(v.begin(), v.end(), double(0)) / v.size();
        var = 0;
        skew = 0;
        kurt = 0;
        samples = v.size();
        for (int i=0; i<v.size(); i++) {
            double d = (v[i] - mean);
            double d2 = d*d;
            var += d2;
            skew += d*d2;
            kurt += d2*d2;
        }
        var /= v.size();
        stddev = std::sqrt(var);
        skew /= v.size() * stddev * var;
        kurt /= v.size() * var * var;
        kurt -= 3;

        std::sort(v.begin(), v.end());

        for (int i=0; i<100; i++) {
            int ndex = (samples*i)/100;
            perc[i] = v.at(ndex);
            //printf("perc %d, %g\n", i, perc[i]);
        }

        min = *std::min_element(v.begin(), v.end());
        max = *std::max_element(v.begin(), v.end());

        //printf("samples %g, stddev %g, mean %g, skew %g, kurt %g, max %g, min %g\n", 
        //  samples, stddev, mean, skew, kurt, max, min);
    }

};
#endif

#endif // __STATS_H__
