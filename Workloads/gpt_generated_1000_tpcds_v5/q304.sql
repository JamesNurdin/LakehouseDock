WITH avg_return AS (
    SELECT avg(cr_return_amt_inc_tax) AS overall_avg
    FROM catalog_returns
)
SELECT
    w.w_warehouse_name,
    'HighAmount' AS category,
    SUM(cr.cr_return_amt_inc_tax) AS total_return_inc_tax,
    COUNT(*) AS return_cnt,
    (SELECT overall_avg FROM avg_return) AS overall_avg_return
FROM catalog_returns cr
JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
WHERE cr.cr_return_amt_inc_tax > 1000
GROUP BY w.w_warehouse_name

UNION ALL

SELECT
    w.w_warehouse_name,
    'FreeShip' AS category,
    SUM(cr.cr_return_amt_inc_tax) AS total_return_inc_tax,
    COUNT(*) AS return_cnt,
    (SELECT overall_avg FROM avg_return) AS overall_avg_return
FROM catalog_returns cr
JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
WHERE cr.cr_return_ship_cost = 0
  AND EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_refunded_customer_sk = cr.cr_refunded_customer_sk
          AND cr2.cr_return_amount > 500
    )
GROUP BY w.w_warehouse_name

ORDER BY total_return_inc_tax DESC
LIMIT 100
