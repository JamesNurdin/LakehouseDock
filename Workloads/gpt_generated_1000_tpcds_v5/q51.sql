WITH ws_f AS (
    SELECT
        ws.ws_order_number,
        ws.ws_warehouse_sk,
        ws.ws_web_site_sk,
        ws.ws_quantity,
        ws.ws_ext_discount_amt,
        ws.ws_net_profit,
        ws.ws_sold_date_sk
    FROM web_sales ws
    WHERE ws.ws_ext_discount_amt > 1000
      AND ws.ws_quantity BETWEEN 1 AND 5
      AND ws.ws_ship_hdemo_sk IN (297, 2472)
      AND ws.ws_ext_sales_price > 500
      AND ws.ws_net_paid > 0
      AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2455000
)
SELECT
    w.w_warehouse_id,
    ws_site.web_name,
    SUM(ws_f.ws_net_profit) AS total_profit,
    AVG(ws_f.ws_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT ws_f.ws_order_number) AS order_cnt,
    MIN(ws_f.ws_sold_date_sk) AS first_sold_date_sk,
    MAX(ws_f.ws_sold_date_sk) AS last_sold_date_sk
FROM ws_f
JOIN warehouse w
    ON ws_f.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_site ws_site
    ON ws_f.ws_web_site_sk = ws_site.web_site_sk
WHERE w.w_state = 'NY'
  AND w.w_city = 'Pine Grove'
  AND ws_site.web_city = 'Lakeview'
  AND ws_site.web_tax_percentage < 0.08
  AND ws_site.web_close_date_sk > 2445000
  AND ws_site.web_gmt_offset BETWEEN -5.00 AND 0.00
GROUP BY w.w_warehouse_id, ws_site.web_name
HAVING SUM(ws_f.ws_net_profit) > (
    SELECT AVG(ws2.ws_net_profit)
    FROM web_sales ws2
    WHERE ws2.ws_ext_discount_amt > 1000
)
ORDER BY total_profit DESC
LIMIT 100
