WITH cr_agg AS (
    SELECT
        cr_warehouse_sk,
        SUM(cr_return_amount) AS total_return_amount,
        AVG(cr_fee) AS avg_fee,
        MAX(cr_return_quantity) AS max_return_qty,
        COUNT(*) AS return_cnt
    FROM tpcds.catalog_returns
    WHERE cr_fee > 20
      AND cr_return_amount > 0
      AND cr_warehouse_sk IN (4, 19, 6, 20, 3)
    GROUP BY cr_warehouse_sk
)
SELECT
    w.w_warehouse_id,
    w.w_city,
    w.w_zip,
    cr_agg.total_return_amount,
    cr_agg.avg_fee,
    cr_agg.max_return_qty,
    cr_agg.return_cnt
FROM cr_agg
JOIN tpcds.warehouse w
  ON cr_agg.cr_warehouse_sk = w.w_warehouse_sk
WHERE w.w_city = 'Liberty'
  AND w.w_zip = '63451'
  AND EXISTS (
        SELECT 1
        FROM tpcds.catalog_returns cr2
        WHERE cr2.cr_warehouse_sk = w.w_warehouse_sk
          AND cr2.cr_return_quantity > 5
    )
ORDER BY cr_agg.total_return_amount DESC
LIMIT 100
