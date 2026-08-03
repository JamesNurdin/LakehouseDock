WITH sampled_returns AS (
    SELECT
        cr.cr_returning_hdemo_sk,
        cr.cr_refunded_hdemo_sk,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_warehouse_sk,
        cr.cr_reversed_charge,
        hd.hd_income_band_sk,
        hd.hd_dep_count,
        hd.hd_vehicle_count,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM catalog_returns cr
    TABLESAMPLE BERNOULLI (10)
    JOIN household_demographics hd
      ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE cr.cr_return_amount > 50
      AND cr.cr_reversed_charge < 100
      AND hd.hd_dep_count >= 2
      AND ib.ib_lower_bound >= 60000
),
aggregated_by_income AS (
    SELECT
        ib_lower_bound,
        ib_upper_bound,
        SUM(cr_return_amount) AS total_return_amount,
        AVG(cr_return_quantity) AS avg_return_qty,
        COUNT(*) AS return_cnt
    FROM sampled_returns
    GROUP BY ib_lower_bound, ib_upper_bound
    HAVING SUM(cr_return_amount) > 1000
)
SELECT
    ib_lower_bound,
    ib_upper_bound,
    total_return_amount,
    avg_return_qty,
    return_cnt,
    ROW_NUMBER() OVER (PARTITION BY ib_lower_bound ORDER BY total_return_amount DESC) AS income_band_rank
FROM aggregated_by_income
ORDER BY total_return_amount DESC
LIMIT 100
