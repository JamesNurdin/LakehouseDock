WITH store_monthly AS (
   SELECT
       d.d_year,
       d.d_month_seq AS month_seq,
       'Store' AS sales_channel,
       SUM(ss.ss_net_paid_inc_tax) AS total_net_paid
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   WHERE d.d_year BETWEEN 1999 AND 2000
     AND EXISTS (
         SELECT 1
         FROM promotion p
         WHERE p.p_promo_sk = ss.ss_promo_sk
           AND p.p_discount_active = 'Y'
     )
   GROUP BY d.d_year, d.d_month_seq
),
catalog_monthly AS (
   SELECT
       d.d_year,
       d.d_month_seq AS month_seq,
       'Catalog' AS sales_channel,
       SUM(cs.cs_net_paid_inc_tax) AS total_net_paid
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   WHERE d.d_year BETWEEN 1999 AND 2000
     AND EXISTS (
         SELECT 1
         FROM promotion p
         WHERE p.p_promo_sk = cs.cs_promo_sk
           AND p.p_discount_active = 'Y'
     )
   GROUP BY d.d_year, d.d_month_seq
)
SELECT *
FROM store_monthly
UNION ALL
SELECT *
FROM catalog_monthly
ORDER BY d_year, month_seq, sales_channel
LIMIT 100
