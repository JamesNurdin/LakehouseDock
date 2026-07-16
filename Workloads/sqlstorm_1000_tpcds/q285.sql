WITH sales AS (
    SELECT cs.cs_sold_date_sk AS date_sk,
           cs.cs_sold_time_sk AS time_sk,
           cs.cs_item_sk AS item_sk,
           cs.cs_promo_sk AS promo_sk,
           cs.cs_net_paid AS net_paid,
           cs.cs_net_profit AS net_profit,
           'catalog' AS channel
    FROM catalog_sales cs
    UNION ALL
    SELECT ss.ss_sold_date_sk,
           ss.ss_sold_time_sk,
           ss.ss_item_sk,
           ss.ss_promo_sk,
           ss.ss_net_paid,
           ss.ss_net_profit,
           'store'
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_sold_date_sk,
           ws.ws_sold_time_sk,
           ws.ws_item_sk,
           ws.ws_promo_sk,
           ws.ws_net_paid,
           ws.ws_net_profit,
           'web'
    FROM web_sales ws
)
SELECT d.d_year,
       i.i_category,
       i.i_class,
       COALESCE(p.p_promo_name, 'NONE') AS promo_name,
       t.t_hour,
       s.channel,
       SUM(s.net_paid) AS total_net_paid,
       SUM(s.net_profit) AS total_net_profit,
       COUNT(*) AS sales_cnt,
       RANK() OVER (PARTITION BY d.d_year ORDER BY SUM(s.net_paid) DESC) AS sales_rank_year
FROM sales s
JOIN date_dim d ON s.date_sk = d.d_date_sk
JOIN time_dim t ON s.time_sk = t.t_time_sk
JOIN item i ON s.item_sk = i.i_item_sk
LEFT JOIN promotion p ON s.promo_sk = p.p_promo_sk
GROUP BY d.d_year,
         i.i_category,
         i.i_class,
         p.p_promo_name,
         t.t_hour,
         s.channel
ORDER BY d.d_year, total_net_paid DESC
LIMIT 100
