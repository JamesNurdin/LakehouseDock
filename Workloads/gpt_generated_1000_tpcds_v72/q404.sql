WITH agg_returns AS (
    SELECT
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        ca.ca_city,
        SUM(cr.cr_refunded_cash) AS total_refunded_cash,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN customer cust
        ON cr.cr_refunded_customer_sk = cust.c_customer_sk
    JOIN customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE cr.cr_refunded_cash > 100                -- predicate 1
      AND cr.cr_return_quantity >= 1               -- predicate 2
      AND hd.hd_vehicle_count >= 0                -- predicate 3
      AND ca.ca_state = 'TX'                       -- predicate 4
      AND cust.c_birth_year BETWEEN 1950 AND 1990 -- predicate 5
    GROUP BY ib.ib_lower_bound, ib.ib_upper_bound, ca.ca_city
    HAVING SUM(cr.cr_refunded_cash) > 500          -- predicate 6
)
SELECT DISTINCT
    ib_lower_bound,
    ib_upper_bound,
    ca_city,
    total_refunded_cash,
    return_cnt,
    AVG(total_refunded_cash) OVER (PARTITION BY ib_lower_bound ORDER BY ib_upper_bound) AS avg_refunded_by_band,
    RANK() OVER (ORDER BY total_refunded_cash DESC) AS cash_rank
FROM agg_returns
ORDER BY total_refunded_cash DESC
LIMIT 100
