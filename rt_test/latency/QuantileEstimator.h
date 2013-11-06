/* 

    QuantileEstimator is a useful class for dynamically estimating and 
    maintaining percentile data for dynamic data as the observations
    arrive. Normally percentiles are computed by collected the data
    set, sorting, then indexing by the percentile result required. This
    is an intractable approach as storage requirements become large, or
    for applications that require some real-time access to percentile data
    without incurring the uncertain performance impact of a vector sort. 
    
    Note that Boost has an algorithm for computing online percentiles,
    but Boost can consume more than expected amount of load image space, 
    and can have unexpected performance impacts. Plus I like to understand
    what the code is doing, and what better to do that than rip it yourself. :)

    I've tested this for various Random number distributions with known
    analytical solutions to various quantiles - and it's good. Need
    to unit-test 'ize this stuff, but not there yet.

    For more information on the algorithm see the following paper. 

    http://www.cs.wustl.edu/~jain/papers/ftp/psqr.pdf

    Usage ....

    double perc95 = 0.95; // for the 95th percentile
    double perc50 = 0.95; // for the 50th percentile, 
                          // or commonly known as median

    QuantileEstimator *pperc95 = new QuantileEstimator(perc95);
    QuantileEstimator *pperc50 = new QuantileEstimator(perc50);

    for ( <some number of iterations ....> )  {

        pperc95->Push ( yourData );
        pperc50->Push ( yourData );

    }
    
    double quant50 = pperc50->Quantile();
    double quant95 = pperc95->Quantile();


    Vince Bridgers, provided for Altera's use
    vbridgers2013@gmail.com

class QuantileEstimator {
private:

public:
    // ctor, takes the percentile desired as the 
    // input parameter. 
    //
    // Note that the ctor must be called for each 
    // percentile desired
    QuantileEstimator(double perc);

    // Pushes a data observation to the estimator.
    // Returns the current quantile 
    double
    Push(double newValue);

    // returns the current quantile
    double
    Quantile(void);
};

*/

#pragma once
#ifndef __QUANTILEESTIMATOR_H__
#define __QUANTILEESTIMATOR_H__

#include <iostream>
#include <stdlib.h>
#include <algorithm>
#include <cmath>

class QuantileEstimator {
private:

    typedef struct _Marker {
        double q;
        double np;
        double dn;
        double n;
    } Marker, *pMarker;

    Marker              marker[6];
    unsigned long long  m_samples;
    std::vector<double> firstfive;
    double              m_perc;
    int k;
    int d;

    double
    ParabolicEstimate(Marker marker[], size_t i, int di)
    {
        double est = marker[i].q + (di / (marker[i + 1].n - marker[i - 1].n)) *
            ((marker[i].n - marker[i - 1].n + di) * (marker[i + 1].q - marker[i].q) / (marker[i + 1].n -
            marker[i].n) +
            (marker[i + 1].n - marker[i].n - di) * (marker[i].q - marker[i - 1].q) / (marker[i].n - marker[i -
            1].n));

        return est;
    }


    double
    LinearEstimate(Marker marker[], size_t i, int di)
    {
        return marker[i].q + di * (marker[i + di].q - marker[i].q) / (marker[i + di].n - marker[i].n);
    }

public:
    QuantileEstimator(double perc)
    {
        memset(marker, 0, sizeof(marker));
        m_samples = 0;
        m_perc = perc;
        k=0;
        d=0;
    }

    double
    push(double newValue)
    {
        double val=0.0;
        if (m_samples < 5) {
            firstfive.push_back(newValue);
            m_samples++;
            return val;
        }

        if (m_samples == 5) {
            std::sort(firstfive.begin(), firstfive.end());

            for (int i = 1; i <= 5; i++) {
                marker[i].q = firstfive.at(i - 1); // Marker heights

                marker[i].n = i; // Marker positions
            }

            // desired marker positions
            marker[1].np = 1;
            marker[2].np = 1 + 2 * m_perc;
            marker[3].np = 1 + 4 * m_perc;
            marker[4].np = 3 + 2 * m_perc;
            marker[5].np = 5;

            // marker increments
            marker[1].dn = 0;
            marker[2].dn = m_perc / 2;
            marker[3].dn = m_perc;
            marker[4].dn = (1 + m_perc) / 2;
            marker[5].dn = 1;
        }

        m_samples++;

        if (newValue < marker[1].q) {
            marker[1].q = newValue;
            k = 1;
        } else if (newValue < marker[2].q) {
            k = 1;
        } else if (newValue < marker[3].q) {
            k = 2;
        } else if (newValue < marker[4].q) {
            k = 3;
        } else if (newValue <= marker[5].q) {
            k = 4;
        } else {
            marker[5].q = newValue;
            k = 4;
        }

        // 2. Increment positions of m
        for (int i = k + 1; i <= 5; i++) {
            marker[i].n++;
        }
        for (int i = 1; i <= 5; i++) {
            marker[i].np += marker[i].dn;
        }

        // 3. Adjust heights of m 2-4 if necessary
        for (int i = 2; i <= 4; i++) {
            double di;
            di = marker[i].np - marker[i].n;
            if (
                ((di >= 1) && ((marker[i + 1].n - marker[i].n) > 1)) ||
                ((di <= -1) && ((marker[i - 1].n - marker[i].n) < -1))
               ) {

                double qip;
                d = di >= 0 ? 1 : -1;
                qip = ParabolicEstimate(marker, i, d);
                if (marker[i - 1].q < qip && qip < marker[i + 1].q)
                    marker[i].q = qip;
                else
                    marker[i].q = LinearEstimate(marker, i, d);

                marker[i].n += d;
            }
        }


        if (m_perc == 0.0) {
            return marker[1].q;
        } else if (m_perc == 1.0)  {
            return marker[5].q;
        } else {
            return marker[3].q;
        }
        return marker[3].q; 
    }

    double
    quantile(void)
    {
        return marker[3].q;
    }

};


class Quantiles {
public:
    QuantileEstimator *qs[100];

    Quantiles()
    {
        for (int i=0; i<100; i++) {
            qs[i] = new QuantileEstimator( (double)((double)i/100.0));
        }
    }

    void
    Push(double x)
    {
        for (int i=0; i<100; i++) {
            qs[i]->push(x);
        }
    }

    double
    quantile(int i)
    {
        if (i<0) {
            return 0.0;
        }
        if (i>99) {
            return 0.0;
        }
        return qs[i]->quantile();
    }

};

#endif // __QUANTILEESTIMATOR_H__
