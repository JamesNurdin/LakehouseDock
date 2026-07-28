WITH catalog_data AS (
   SELECT
      d.d_year AS year,
      COALESCE(r.r_reason_desc, 'All Reasons') AS reason,
      SUM(cs.cs_ext_sales_price) AS total_sales,
      SUM(cr.cr_return_amount) AS total_returns,
      CASE
        WHEN SUM(cs.cs_ext_sales_price) = 0 THEN 0
        ELSE (SUM(cs.cs_ext_sales_price) - SUM(cr.cr_return_amount)) / SUM(cs.cs_ext_sales_price)
      END AS retention_ratio,
      ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(cs.cs_ext_sales_price) DESC) AS sales_rank,
      'catalog' AS source,
      (SELECT AVG(p2.p_cost) FROM promotion p2) AS avg_promo_cost,
      CASE
        WHEN (SUM(cs.cs_ext_sales_price) - SUM(cr.cr_return_amount)) / NULLIF(SUM(cs.cs_ext_sales_price), 0) >= 0.9 THEN 'High'
        WHEN (SUM(cs.cs_ext_sales_price) - SUM(cr.cr_return_amount)) / NULLIF(SUM(cs.cs_ext_sales_price), 0) >= 0.7 THEN 'Medium'
        ELSE 'Low'
      END AS retention_category
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   LEFT JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
   LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
   WHERE d.d_year BETWEEN 2000 AND 2002
   GROUP BY GROUPING SETS ((d.d_year, r.r_reason_desc), (d.d_year))
),
store_data AS (
   SELECT
      d.d_year AS year,
      COALESCE(r.r_reason_desc, 'All Reasons') AS reason,
      SUM(ss.ss_ext_sales_price) AS total_sales,
      SUM(sr.sr_return_amt_inc_tax) AS total_returns,
      CASE
        WHEN SUM(ss.ss_ext_sales_price) = 0 THEN 0
        ELSE (SUM(ss.ss_ext_sales_price) - SUM(sr.sr_return_amt_inc_tax)) / SUM(ss.ss_ext_sales_price)
      END AS retention_ratio,
      ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS sales_rank,
      'store' AS source,
      (SELECT AVG(p2.p_cost) FROM promotion p2) AS avg_promo_cost,
      CASE
        WHEN (SUM(ss.ss_ext_sales_price) - SUM(sr.sr_return_amt_inc_tax)) / NULLIF(SUM(ss.ss_ext_sales_price), 0) >= 0.9 THEN 'High'
        WHEN (SUM(ss.ss_ext_sales_price) - SUM(sr.sr_return_amt_inc_tax)) / NULLIF(SUM(ss.ss_ext_sales_price), 0) >= 0.7 THEN 'Medium'
        ELSE 'Low'
      END AS retention_category
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
   LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
   WHERE d.d_year BETWEEN 2000 AND 2002
     AND EXISTS (
         SELECT 1
         FROM promotion p
         WHERE p.p_promo_sk = ss.ss_promo_sk
           AND p.p_start_date_sk = (
               SELECT MAX(d2.d_date_sk)
               FROM date_dim d2
               WHERE d2.d_year = 2000
           )
     )
   GROUP BY GROUPING SETS ((d.d_year, r.r_reason_desc), (d.d_year))
)
SELECT
   year,
   reason,
   total_sales,
   total_returns,
   retention_ratio,
   retention_category,
   sales_rank,
   source,
   avg_promo_cost
FROM catalog_data
UNION ALL
SELECT
   year,
   reason,
   total_sales,
   total_returns,
   retention_ratio,
   retention_category,
   sales_rank,
   source,
   avg_promo_cost
FROM store_data
ORDER BY year, reason, total_sales DESC
LIMIT 100
