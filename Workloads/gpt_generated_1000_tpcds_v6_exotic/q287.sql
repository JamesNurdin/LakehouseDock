WITH filtered_store_sales AS (
   SELECT
     ss.ss_store_sk,
     ss.ss_promo_sk,
     ss.ss_ext_sales_price,
     ss.ss_net_profit,
     s.s_store_name,
     p.p_promo_name
   FROM store_sales ss
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
   WHERE regexp_like(s.s_store_name, '^.*Market.*$')
     AND regexp_like(p.p_promo_name, '.*[0-9]+% OFF.*')
)

SELECT
  fs.s_store_name,
  substring(fs.s_store_name, 1, 10) AS short_name,
  COUNT(*) AS sales_transactions,
  SUM(fs.ss_ext_sales_price) AS total_sales,
  SUM(fs.ss_net_profit) AS total_profit,
  CASE
    WHEN SUM(fs.ss_net_profit) > 200000 THEN 'High'
    WHEN SUM(fs.ss_net_profit) > 50000 THEN 'Medium'
    ELSE 'Low'
  END AS profit_category,
  (SELECT avg(p2.p_cost)
   FROM promotion p2
   WHERE p2.p_promo_sk = fs.ss_promo_sk) AS avg_promo_cost,
  CASE
    WHEN EXISTS (
      SELECT 1
      FROM catalog_sales cs
      JOIN promotion p2 ON cs.cs_promo_sk = p2.p_promo_sk
      JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
      WHERE p2.p_promo_sk = fs.ss_promo_sk
        AND regexp_like(cc.cc_name, '^.*Center.*$')
        AND cs.cs_quantity > 5
    )
    THEN 'Has Big Catalog Sales'
    ELSE 'No Big Catalog Sales'
  END AS catalog_sales_flag
FROM filtered_store_sales fs
GROUP BY
  fs.s_store_name,
  fs.ss_promo_sk,
  substring(fs.s_store_name, 1, 10)
ORDER BY total_sales DESC
LIMIT 100
