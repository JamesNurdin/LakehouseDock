WITH date_info AS (
    SELECT d_date_sk,
           d_year,
           d_month_seq,
           d_moy,
           d_qoy
    FROM date_dim
    WHERE d_year BETWEEN 1998 AND 1999
)
SELECT
    di.d_year AS year,
    di.d_month_seq AS month,
    wh.w_warehouse_name AS warehouse,
    r.r_reason_desc AS reason,
    SUM(cr.cr_net_loss) AS total_net_loss,
    CASE WHEN SUM(cr.cr_net_loss) > 1000 THEN 'High' ELSE 'Low' END AS loss_category,
    'Catalog' AS source_type
FROM catalog_returns cr
JOIN date_info di ON cr.cr_returned_date_sk = di.d_date_sk
JOIN warehouse wh ON cr.cr_warehouse_sk = wh.w_warehouse_sk
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
WHERE wh.w_country = 'United States'
GROUP BY CUBE (di.d_year, di.d_month_seq, wh.w_warehouse_name, r.r_reason_desc)

UNION ALL

SELECT
    di.d_year AS year,
    di.d_month_seq AS month,
    wh.w_warehouse_name AS warehouse,
    r.r_reason_desc AS reason,
    SUM(wr.wr_net_loss) AS total_net_loss,
    CASE WHEN SUM(wr.wr_net_loss) > 1000 THEN 'High' ELSE 'Low' END AS loss_category,
    'Web' AS source_type
FROM web_returns wr
JOIN date_info di ON wr.wr_returned_date_sk = di.d_date_sk
JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
JOIN warehouse wh ON ws.ws_warehouse_sk = wh.w_warehouse_sk
JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
WHERE wh.w_country = 'United States'
GROUP BY CUBE (di.d_year, di.d_month_seq, wh.w_warehouse_name, r.r_reason_desc)

ORDER BY year, month, warehouse, reason, total_net_loss DESC
LIMIT 100
