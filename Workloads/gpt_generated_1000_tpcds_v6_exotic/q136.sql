WITH ws AS (
    SELECT
        ws_sold_date_sk,
        ws_warehouse_sk,
        ws_web_site_sk,
        ws_order_number,
        ws_net_profit
    FROM web_sales
)
SELECT
    w.w_warehouse_name,
    w.w_city,
    CONCAT(w.w_state, '-', w.w_zip) AS warehouse_code,
    SUBSTR(CAST(MIN(ws.ws_order_number) AS VARCHAR), 1, 5) AS order_prefix,
    REGEXP_EXTRACT(w.w_zip, '(\\d{3})') AS zip_prefix,
    SUM(ws.ws_net_profit) AS total_profit,
    SUBSTR(web_site.web_name, 1, 5) AS site_name_prefix
FROM ws
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_site ON ws.ws_web_site_sk = web_site.web_site_sk
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE w.w_city LIKE 'San%'
  AND REGEXP_LIKE(web_site.web_name, '.*Online.*')
  AND d.d_year = 2002
GROUP BY
    w.w_warehouse_name,
    w.w_city,
    w.w_state,
    w.w_zip,
    web_site.web_name
HAVING SUM(ws.ws_net_profit) > 10000
ORDER BY total_profit DESC
LIMIT 100
