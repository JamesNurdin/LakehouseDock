WITH unified_sales AS (
  SELECT ss.ss_sold_date_sk AS sold_date_sk,
         ss.ss_net_paid AS net_paid,
         ss.ss_net_profit AS net_profit,
         st.s_state AS state,
         'store' AS channel
    FROM store_sales ss
    JOIN store st ON ss.ss_store_sk = st.s_store_sk
  UNION ALL
  SELECT ws.ws_sold_date_sk AS sold_date_sk,
         ws.ws_net_paid AS net_paid,
         ws.ws_net_profit AS net_profit,
         wsite.web_state AS state,
         'web' AS channel
    FROM web_sales ws
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
  UNION ALL
  SELECT cs.cs_sold_date_sk AS sold_date_sk,
         cs.cs_net_paid AS net_paid,
         cs.cs_net_profit AS net_profit,
         wh.w_state AS state,
         'catalog' AS channel
    FROM catalog_sales cs
    JOIN warehouse wh ON cs.cs_warehouse_sk = wh.w_warehouse_sk
)
SELECT d.d_year,
       d.d_moy AS month,
       us.state,
       us.channel,
       sum(us.net_paid) AS total_net_paid,
       sum(us.net_profit) AS total_net_profit,
       count(*) AS transaction_count,
       approx_distinct(us.net_paid) AS approx_distinct_net_paid
FROM unified_sales us
JOIN date_dim d ON us.sold_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2002
GROUP BY d.d_year, d.d_moy, us.state, us.channel
ORDER BY d.d_year, d.d_moy, us.state, us.channel
