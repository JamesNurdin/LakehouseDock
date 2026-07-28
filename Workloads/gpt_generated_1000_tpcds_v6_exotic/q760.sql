WITH sales_agg AS (
  SELECT
    p.p_promo_id,
    p.p_promo_name,
    i.i_brand,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(CASE WHEN cs.cs_ext_discount_amt > 100 THEN cs.cs_ext_sales_price ELSE 0 END) AS high_discount_sales
  FROM catalog_sales cs
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  WHERE regexp_like(p.p_channel_details, '(?i)companies')
    AND p.p_promo_name LIKE 'A%'
  GROUP BY p.p_promo_id, p.p_promo_name, i.i_brand
)
SELECT
  p_promo_id,
  p_promo_name,
  i_brand,
  CONCAT(p_promo_name, ' - ', i_brand) AS promo_brand_desc,
  SUBSTR(p_promo_name, 1, 5) AS promo_name_prefix,
  total_sales,
  high_discount_sales,
  CASE WHEN high_discount_sales / NULLIF(total_sales, 0) > 0.5 THEN 'High Discount Ratio' ELSE 'Low Discount Ratio' END AS discount_ratio_category,
  RANK() OVER (PARTITION BY i_brand ORDER BY total_sales DESC) AS brand_promo_rank,
  SUM(total_sales) OVER (PARTITION BY i_brand) AS brand_total_sales
FROM sales_agg
ORDER BY total_sales DESC
LIMIT 100
