WITH
    sampled_hd AS (
        SELECT
            hd_demo_sk,
            hd_income_band_sk,
            hd_dep_count,
            hd_vehicle_count
        FROM household_demographics
        TABLESAMPLE BERNOULLI (20)
    ),
    agg_returns AS (
        SELECT
            cr_refunded_hdemo_sk AS hd_demo_sk,
            COUNT(*) AS cnt_returns,
            SUM(cr_return_amount) AS sum_return_amount,
            AVG(cr_return_amount) AS avg_return_amount
        FROM catalog_returns
        WHERE cr_return_amount > 50
          AND cr_return_quantity >= 1
          AND cr_reversed_charge < 500
        GROUP BY cr_refunded_hdemo_sk
    ),
    excluded_orders AS (
        SELECT cr_order_number
        FROM catalog_returns
        WHERE cr_return_amount > 300
        EXCEPT
        SELECT cr_order_number
        FROM catalog_returns
        WHERE cr_return_quantity = 0
    )
SELECT
    hd_refunded.hd_demo_sk,
    hd_refunded.hd_income_band_sk,
    hd_refunded.hd_dep_count,
    agg.cnt_returns,
    agg.sum_return_amount,
    agg.avg_return_amount
FROM agg_returns agg
JOIN sampled_hd hd_refunded
    ON agg.hd_demo_sk = hd_refunded.hd_demo_sk
WHERE EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_returning_hdemo_sk = hd_refunded.hd_demo_sk
          AND cr2.cr_return_amount > 100
    )
  AND hd_refunded.hd_vehicle_count >= 2
  AND hd_refunded.hd_income_band_sk IN (4, 8, 9, 16, 18)
  AND agg.hd_demo_sk NOT IN (SELECT cr_order_number FROM excluded_orders)
ORDER BY agg.sum_return_amount DESC
LIMIT 100
