WITH per_demo_agg AS (
    SELECT
        cr.cr_refunded_hdemo_sk AS hd_demo_sk,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_return_qty,
        COUNT(*) AS cnt_returns,
        CASE
            WHEN SUM(cr.cr_return_amount) > 1000 THEN 'HIGH'
            WHEN SUM(cr.cr_return_amount) > 500 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS amount_category
    FROM catalog_returns cr
    JOIN household_demographics hd_ref
        ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    WHERE cr.cr_return_quantity >= 1
      AND cr.cr_return_amount > 0
      AND hd_ref.hd_dep_count BETWEEN 1 AND 8
      AND hd_ref.hd_vehicle_count >= 0
    GROUP BY cr.cr_refunded_hdemo_sk
)
SELECT
    amount_category,
    AVG(total_return_amount) AS avg_return_amount,
    SUM(total_return_qty) AS sum_qty,
    COUNT(*) AS demo_count
FROM per_demo_agg
GROUP BY amount_category
HAVING AVG(total_return_amount) > 300
ORDER BY avg_return_amount DESC
LIMIT 100
