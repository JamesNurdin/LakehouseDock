WITH catalog_agg AS (
   SELECT
      p.p_promo_id AS promotion_id,
      cp.cp_catalog_page_id AS catalog_page_id,
      SUM(cs.cs_ext_sales_price) AS total_sales,
      COUNT(DISTINCT cs.cs_order_number) AS orders,
      'catalog' AS source
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   WHERE d.d_year = 2001
     AND p.p_channel_event = 'N'
   GROUP BY p.p_promo_id, cp.cp_catalog_page_id
),
store_agg AS (
   SELECT
      p.p_promo_id AS promotion_id,
      CAST(null AS varchar) AS catalog_page_id,
      SUM(ss.ss_ext_sales_price) AS total_sales,
      COUNT(DISTINCT ss.ss_ticket_number) AS orders,
      'store' AS source
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
   WHERE d.d_year = 2001
     AND p.p_channel_event = 'N'
   GROUP BY p.p_promo_id
)
SELECT *
FROM catalog_agg
UNION ALL
SELECT *
FROM store_agg
ORDER BY total_sales DESC
LIMIT 100
