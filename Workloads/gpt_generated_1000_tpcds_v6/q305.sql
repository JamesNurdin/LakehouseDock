SELECT
    CONCAT(SUBSTRING(ws.web_name, 1, 5), '-', w.w_warehouse_name) AS site_warehouse_label,
    SUM(ws_sales.ws_net_profit) AS total_profit,
    COUNT(*) AS order_count,
    AVG(ws_sales.ws_net_profit) AS avg_profit
FROM tpcds.web_sales ws_sales
JOIN tpcds.date_dim d
  ON ws_sales.ws_sold_date_sk = d.d_date_sk
JOIN tpcds.web_site ws
  ON ws_sales.ws_web_site_sk = ws.web_site_sk
JOIN tpcds.warehouse w
  ON ws_sales.ws_warehouse_sk = w.w_warehouse_sk
WHERE d.d_year = 2022
  AND regexp_like(ws.web_name, '^.*[0-9]{2}.*$')
  AND ws.web_name LIKE '%Market%'
GROUP BY CONCAT(SUBSTRING(ws.web_name, 1, 5), '-', w.w_warehouse_name)
ORDER BY total_profit DESC
LIMIT 100
