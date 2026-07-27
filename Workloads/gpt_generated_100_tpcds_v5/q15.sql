WITH refunded AS (
    SELECT
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_orders
    FROM catalog_returns cr
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE cr.cr_return_amount > 100
      AND hd.hd_vehicle_count >= 2
      AND EXISTS (
          SELECT 1
          FROM income_band ib2
          WHERE ib2.ib_income_band_sk = ib.ib_income_band_sk
            AND ib2.ib_lower_bound >= 50000
      )
    GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
),
returning AS (
    SELECT
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_orders
    FROM catalog_returns cr
    JOIN household_demographics hd
        ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE cr.cr_reversed_charge < 50
      AND hd.hd_dep_count BETWEEN 4 AND 8
    GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
)
SELECT
    'refunded'   AS return_type,
    ib_income_band_sk,
    ib_lower_bound,
    ib_upper_bound,
    total_return_amount,
    distinct_orders
FROM refunded
UNION ALL
SELECT
    'returning' AS return_type,
    ib_income_band_sk,
    ib_lower_bound,
    ib_upper_bound,
    total_return_amount,
    distinct_orders
FROM returning
ORDER BY total_return_amount DESC
LIMIT 100
