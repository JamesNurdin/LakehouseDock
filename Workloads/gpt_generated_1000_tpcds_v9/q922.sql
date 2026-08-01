WITH high_fee AS (
    SELECT
        w.w_warehouse_sk AS warehouse_sk,
        w.w_warehouse_id AS warehouse_id,
        SUM(cr.cr_return_amount) AS total_return_amount,
        AVG(cr.cr_fee) AS avg_fee,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN warehouse w
      ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE cr.cr_fee > 30
      AND cr.cr_return_ship_cost > 1000
      AND w.w_suite_number = 'Suite 260'
    GROUP BY w.w_warehouse_sk, w.w_warehouse_id
),
low_fee AS (
    SELECT
        w.w_warehouse_sk AS warehouse_sk,
        w.w_warehouse_id AS warehouse_id,
        SUM(cr.cr_return_amount) AS total_return_amount,
        AVG(cr.cr_fee) AS avg_fee,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN warehouse w
      ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE cr.cr_fee <= 30
      AND cr.cr_return_ship_cost < 200
      AND w.w_zip = '38048'
    GROUP BY w.w_warehouse_sk, w.w_warehouse_id
),
combined AS (
    SELECT
        high_fee.warehouse_sk,
        high_fee.warehouse_id,
        high_fee.total_return_amount,
        high_fee.avg_fee,
        high_fee.return_cnt
    FROM high_fee
    UNION ALL
    SELECT
        low_fee.warehouse_sk,
        low_fee.warehouse_id,
        low_fee.total_return_amount,
        low_fee.avg_fee,
        low_fee.return_cnt
    FROM low_fee
)
SELECT
    combined.warehouse_sk,
    combined.warehouse_id,
    combined.total_return_amount,
    combined.avg_fee,
    combined.return_cnt
FROM combined
WHERE NOT EXISTS (
    SELECT 1
    FROM catalog_returns cr_ex
    WHERE cr_ex.cr_warehouse_sk = combined.warehouse_sk
      AND cr_ex.cr_fee > 70
)
ORDER BY combined.total_return_amount DESC
LIMIT 100
