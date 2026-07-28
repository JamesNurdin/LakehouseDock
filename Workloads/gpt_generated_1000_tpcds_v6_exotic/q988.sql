/*
  Goal: Calculate yearly return performance by call center division and state, include subtotals via ROLLUP, rank divisions by total return amount within each year, and flag whether a division's return amount is above the yearly average.
*/
WITH agg AS (
    SELECT
        d_ret.d_year                              AS year,
        cc.cc_division_name                       AS division,
        cc.cc_state                               AS state,
        SUM(sr.sr_return_amt)                    AS total_return_amt,
        SUM(sr.sr_store_credit)                  AS total_store_credit,
        COUNT(*)                                 AS return_cnt
    FROM store_returns sr
    JOIN date_dim d_ret
        ON sr.sr_returned_date_sk = d_ret.d_date_sk            -- rule 1
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk                     -- rule 2
    JOIN call_center cc
        ON cc.cc_open_date_sk = d_ret.d_date_sk               -- rule 4 (open date)
    WHERE d_ret.d_current_month = 'Y'           -- predicate 1 (month flag)
      AND sr.sr_store_credit > 100             -- predicate 2 (high store credit)
      AND hd.hd_vehicle_count >= 1            -- predicate 3 (vehicle ownership)
      AND d_ret.d_year BETWEEN 2000 AND 2005 -- predicate 4 (year range)
    GROUP BY ROLLUP (d_ret.d_year, cc.cc_division_name, cc.cc_state)
)
SELECT
    year,
    division,
    state,
    total_return_amt,
    total_store_credit,
    return_cnt,
    RANK() OVER (PARTITION BY year ORDER BY total_return_amt DESC) AS year_return_rank,
    CASE
        WHEN total_return_amt > (
            SELECT AVG(a2.total_return_amt)
            FROM agg a2
            WHERE a2.year = agg.year
        ) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS performance_category
FROM agg
ORDER BY year DESC, year_return_rank
LIMIT 100
