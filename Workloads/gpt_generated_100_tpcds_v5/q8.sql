WITH filtered_sales AS (
    SELECT ws.ws_ship_mode_sk,
           ws.ws_web_site_sk,
           ws.ws_quantity,
           ws.ws_ext_sales_price,
           ws.ws_net_profit
    FROM web_sales ws
    WHERE ws.ws_quantity >= 30
      AND ws.ws_ext_sales_price > 500
)
SELECT sm.sm_type,
       site.web_city,
       COUNT(*) AS order_count,
       SUM(f.ws_ext_sales_price) AS total_sales,
       AVG(f.ws_quantity) AS avg_quantity,
       MIN(f.ws_net_profit) AS min_profit,
       MAX(f.ws_net_profit) AS max_profit
FROM filtered_sales f
JOIN ship_mode sm ON f.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_site site ON f.ws_web_site_sk = site.web_site_sk
WHERE sm.sm_code = 'AIR'
  AND sm.sm_contract = 'qENFQ'
  AND site.web_state = 'CA'
GROUP BY sm.sm_type, site.web_city
ORDER BY total_sales DESC
LIMIT 100
