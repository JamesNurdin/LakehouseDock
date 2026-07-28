WITH sales_filtered AS (
    SELECT ws.ws_order_number,
           ws.ws_net_paid,
           ws.ws_sold_date_sk,
           ws.ws_ship_mode_sk,
           ws.ws_web_site_sk
    FROM web_sales ws
    WHERE NOT EXISTS (
        SELECT 1 FROM web_returns wr
        WHERE wr.wr_order_number = ws.ws_order_number
    )
)
SELECT ws.web_manager,
       substring(ws.web_manager, 1, 3) AS manager_prefix,
       SUM(sf.ws_net_paid) AS total_net_paid,
       COUNT(DISTINCT sf.ws_order_number) AS orders_cnt,
       ROW_NUMBER() OVER (ORDER BY SUM(sf.ws_net_paid) DESC) AS manager_rank
FROM sales_filtered sf
JOIN date_dim d ON sf.ws_sold_date_sk = d.d_date_sk
JOIN ship_mode sm ON sf.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_site ws ON sf.ws_web_site_sk = ws.web_site_sk
WHERE d.d_year = 2021
  AND regexp_like(ws.web_manager, '^J.*')
  AND sm.sm_carrier LIKE 'D%'
GROUP BY ws.web_manager, substring(ws.web_manager, 1, 3)
ORDER BY total_net_paid DESC
LIMIT 100
