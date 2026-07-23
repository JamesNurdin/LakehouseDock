SELECT d.d_year AS year,
       d.d_moy AS month,
       'store' AS channel,
       SUM(ss.ss_net_profit) AS total_net_profit
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
WHERE d.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
  AND i.i_category = 'Electronics'
  AND i.i_current_price > 100
  AND s.s_state = 'CA'
GROUP BY d.d_year, d.d_moy

UNION ALL

SELECT d.d_year AS year,
       d.d_moy AS month,
       'web' AS channel,
       SUM(ws.ws_net_profit) AS total_net_profit
FROM web_sales ws
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN item i ON ws.ws_item_sk = i.i_item_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE d.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
  AND i.i_category = 'Electronics'
  AND i.i_current_price > 100
  AND wp.wp_type = 'product'
GROUP BY d.d_year, d.d_moy
ORDER BY year, month, channel
LIMIT 100
