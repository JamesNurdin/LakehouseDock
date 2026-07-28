WITH unified_sales AS (
  SELECT
    cs.cs_sold_date_sk AS sale_date_sk,
    cp.cp_department AS category,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    'catalog' AS sales_channel
  FROM catalog_sales cs
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  WHERE cp.cp_department = 'Books'
    AND p.p_discount_active = 'Y'
    AND EXISTS (
      SELECT 1 FROM promotion p2
      WHERE p2.p_promo_sk = cs.cs_promo_sk
        AND p2.p_cost > 100
    )
  GROUP BY cs.cs_sold_date_sk, cp.cp_department

  UNION ALL

  SELECT
    ss.ss_sold_date_sk AS sale_date_sk,
    s.s_state AS category,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    'store' AS sales_channel
  FROM store_sales ss
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  WHERE s.s_state = 'CA'
    AND p.p_discount_active = 'Y'
    AND EXISTS (
      SELECT 1 FROM promotion p2
      WHERE p2.p_promo_sk = ss.ss_promo_sk
        AND p2.p_cost > 100
    )
  GROUP BY ss.ss_sold_date_sk, s.s_state
)
SELECT
  sale_date_sk,
  category,
  total_sales,
  sales_channel,
  RANK() OVER (PARTITION BY sales_channel ORDER BY total_sales DESC) AS sales_rank,
  (SELECT AVG(total_sales) FROM unified_sales) AS avg_total_sales_overall
FROM unified_sales
ORDER BY sale_date_sk DESC, sales_rank
LIMIT 100
