WITH monthly_sales AS (
   SELECT d.d_year, d.d_month_seq, 'store' AS channel, sum(ss.ss_net_paid) AS net_paid
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
   WHERE d.d_year = 2000 AND p.p_discount_active = 'Y'
   GROUP BY d.d_year, d.d_month_seq
   UNION ALL
   SELECT d.d_year, d.d_month_seq, 'web' AS channel, sum(ws.ws_net_paid) AS net_paid
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
   WHERE d.d_year = 2000 AND p.p_discount_active = 'Y'
   GROUP BY d.d_year, d.d_month_seq
   UNION ALL
   SELECT d.d_year, d.d_month_seq, 'catalog' AS channel, sum(cs.cs_net_paid) AS net_paid
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   WHERE d.d_year = 2000 AND p.p_discount_active = 'Y'
   GROUP BY d.d_year, d.d_month_seq
)
SELECT ms.d_year,
       ms.d_month_seq,
       ms.channel,
       ms.net_paid,
       sum(ms.net_paid) OVER (PARTITION BY ms.channel ORDER BY ms.d_year, ms.d_month_seq ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_3_month_sum
FROM monthly_sales ms
ORDER BY ms.channel, ms.d_year, ms.d_month_seq
LIMIT 100
