WITH avg_loss AS (
    SELECT avg(cr_net_loss) AS avg_net_loss
    FROM catalog_returns
)

SELECT
    w.w_warehouse_name,
    d.d_year,
    SUM(cr.cr_net_loss) AS total_net_loss,
    COUNT(*) AS return_cnt,
    CASE WHEN SUM(cr.cr_net_loss) > (SELECT avg_net_loss FROM avg_loss) THEN 'High' ELSE 'Low' END AS loss_category
FROM catalog_returns cr
JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
WHERE d.d_fy_week_seq <= 5
  AND w.w_gmt_offset = -5.00
  AND EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_refunded_customer_sk = c.c_customer_sk
          AND cr2.cr_returned_date_sk = cr.cr_returned_date_sk
          AND cr2.cr_order_number <> cr.cr_order_number
    )
GROUP BY w.w_warehouse_name, d.d_year

UNION ALL

SELECT
    w.w_warehouse_name,
    d.d_year,
    SUM(cr.cr_net_loss) AS total_net_loss,
    COUNT(*) AS return_cnt,
    CASE WHEN SUM(cr.cr_net_loss) > (SELECT avg_net_loss FROM avg_loss) THEN 'High' ELSE 'Low' END AS loss_category
FROM catalog_returns cr
JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
WHERE cr.cr_store_credit > 1000.00
  AND d.d_week_seq >= 10
  AND w.w_warehouse_name IS NOT NULL
GROUP BY w.w_warehouse_name, d.d_year
ORDER BY total_net_loss DESC
LIMIT 100
