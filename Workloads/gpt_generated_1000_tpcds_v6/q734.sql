WITH sales_2020 AS (
   SELECT
       ws.ws_web_site_sk,
       ws.ws_quantity,
       ws.ws_item_sk,
       ws.ws_net_profit,
       ws.ws_net_paid_inc_ship,
       ws.ws_sold_date_sk
   FROM web_sales ws
   JOIN date_dim d
     ON ws.ws_sold_date_sk = d.d_date_sk
   WHERE d.d_year = 2020
)
SELECT
    ws_site.web_site_sk AS site_id,
    ws_site.web_name,
    ws_site.web_manager,
    ws_site.web_state,
    COUNT(*) AS total_orders,
    SUM(s.ws_net_profit) AS total_net_profit,
    AVG(s.ws_net_profit) AS avg_net_profit,
    CASE
        WHEN SUM(s.ws_net_profit) > 0 THEN 'POSITIVE'
        ELSE 'NON_POSITIVE'
    END AS profit_category,
    CONCAT(CAST(COUNT(DISTINCT s.ws_quantity) AS varchar), '-', ws_site.web_state) AS qty_state_key,
    (SELECT avg(ws2.ws_net_profit)
     FROM web_sales ws2
     WHERE ws2.ws_web_site_sk = ws_site.web_site_sk) AS avg_site_profit_all_years
FROM sales_2020 s
JOIN web_site ws_site
  ON s.ws_web_site_sk = ws_site.web_site_sk
WHERE regexp_like(ws_site.web_manager, '^John')
  AND ws_site.web_zip LIKE '4%'
  AND EXISTS (
        SELECT 1
        FROM store st
        WHERE st.s_state = ws_site.web_state
          AND regexp_like(st.s_suite_number, '^Suite [5-9][0-9][0-9]$')
  )
GROUP BY
    ws_site.web_site_sk,
    ws_site.web_name,
    ws_site.web_manager,
    ws_site.web_state
ORDER BY total_net_profit DESC
LIMIT 100
