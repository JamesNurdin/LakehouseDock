WITH catalog_agg AS (
  SELECT
    d.d_date AS sales_date,
    p.p_promo_name AS promo_name,
    SUM(cs.cs_ext_sales_price) AS total_sales
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  WHERE p.p_channel_dmail = 'Y'
    AND d.d_year = 2001
    AND EXISTS (
      SELECT 1
      FROM warehouse w
      JOIN inventory i ON w.w_warehouse_sk = i.inv_warehouse_sk
      WHERE i.inv_date_sk = d.d_date_sk
        AND w.w_state = 'CA'
    )
  GROUP BY d.d_date, p.p_promo_name
),
store_agg AS (
  SELECT
    d.d_date AS sales_date,
    p.p_promo_name AS promo_name,
    SUM(ss.ss_ext_sales_price) AS total_sales
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  WHERE p.p_channel_dmail = 'Y'
    AND d.d_year = 2001
  GROUP BY d.d_date, p.p_promo_name
),
unioned AS (
  SELECT sales_date, promo_name, total_sales, 'catalog' AS source
  FROM catalog_agg
  UNION ALL
  SELECT sales_date, promo_name, total_sales, 'store' AS source
  FROM store_agg
),
subtotal AS (
  SELECT
    sales_date,
    source,
    SUM(total_sales) AS agg_sales
  FROM unioned
  GROUP BY GROUPING SETS (
    (sales_date, source),
    (sales_date),
    (source),
    ()
  )
)
SELECT
  sales_date,
  source,
  agg_sales,
  CASE
    WHEN agg_sales > 200000 THEN 'Very High'
    WHEN agg_sales > 100000 THEN 'High'
    WHEN agg_sales > 50000 THEN 'Medium'
    ELSE 'Low'
  END AS sales_bucket,
  ROW_NUMBER() OVER (ORDER BY agg_sales DESC) AS sales_rank
FROM subtotal
ORDER BY sales_rank
LIMIT 100
