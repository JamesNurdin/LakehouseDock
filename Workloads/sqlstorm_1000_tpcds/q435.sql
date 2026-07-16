WITH combined_sales AS (
  SELECT d.d_year AS d_year,
         'store' AS channel,
         p.p_promo_name AS promo_name,
         ss.ss_net_paid AS sales_amount,
         ss.ss_net_profit AS profit
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  UNION ALL
  SELECT d.d_year,
         'catalog' AS channel,
         p.p_promo_name,
         cs.cs_net_paid,
         cs.cs_net_profit
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  UNION ALL
  SELECT d.d_year,
         'web' AS channel,
         p.p_promo_name,
         ws.ws_net_paid,
         ws.ws_net_profit
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
)
SELECT d_year,
       channel,
       promo_name,
       total_sales,
       total_profit,
       RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank
FROM (
  SELECT d_year,
         channel,
         promo_name,
         SUM(sales_amount) AS total_sales,
         SUM(profit) AS total_profit
  FROM combined_sales
  WHERE d_year BETWEEN 2000 AND 2002
  GROUP BY d_year, channel, promo_name
) agg
ORDER BY d_year, sales_rank
LIMIT 100
