SELECT
    d.d_year AS year,
    r.r_reason_desc AS reason,
    MIN(CONCAT(w.w_city, ', ', w.w_state)) AS location,
    MIN(regexp_extract(r.r_reason_desc, '(\\w+)$', 1)) AS last_word,
    SUM(wr.wr_net_loss) AS total_loss,
    CASE WHEN SUM(wr.wr_net_loss) > 1000 THEN 'High' ELSE 'Low' END AS loss_category
FROM web_returns wr
JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
WHERE ws.ws_warehouse_sk IN (
        SELECT w_warehouse_sk
        FROM warehouse
        WHERE w_city LIKE 'San%'
    )
  AND regexp_like(r.r_reason_desc, 'fault')
GROUP BY GROUPING SETS ((d.d_year, r.r_reason_desc), (d.d_year))

UNION DISTINCT

SELECT
    d.d_year AS year,
    r.r_reason_desc AS reason,
    MIN(CONCAT(w.w_city, ', ', w.w_state)) AS location,
    MIN(regexp_extract(r.r_reason_desc, '(\\w+)$', 1)) AS last_word,
    SUM(cr.cr_net_loss) AS total_loss,
    CASE WHEN SUM(cr.cr_net_loss) > 1000 THEN 'High' ELSE 'Low' END AS loss_category
FROM catalog_returns cr
JOIN catalog_sales cs ON cr.cr_order_number = cs.cs_order_number
JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
WHERE cs.cs_warehouse_sk IN (
        SELECT w_warehouse_sk
        FROM warehouse
        WHERE w_city LIKE 'San%'
    )
  AND regexp_like(r.r_reason_desc, 'fault')
GROUP BY GROUPING SETS ((d.d_year, r.r_reason_desc), (d.d_year))

ORDER BY year, reason, loss_category
LIMIT 100
