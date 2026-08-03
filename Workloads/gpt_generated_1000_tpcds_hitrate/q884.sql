WITH sales_union AS (
  SELECT
    d.d_year AS sales_year,
    i.i_category AS category,
    i.i_brand AS brand,
    cs.cs_ext_sales_price AS sales_amount,
    cs.cs_net_profit AS profit_amount,
    concat(i.i_brand, ' ', i.i_category) AS brand_category,
    i.i_item_desc AS item_desc,
    p.p_promo_name AS promo_name
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  WHERE regexp_like(i.i_item_desc, '.*[A-Z]{3}.*')
    AND p.p_promo_name LIKE '%Clearance%'

  UNION DISTINCT

  SELECT
    d.d_year AS sales_year,
    i.i_category AS category,
    i.i_brand AS brand,
    ss.ss_ext_sales_price AS sales_amount,
    ss.ss_net_profit AS profit_amount,
    concat(i.i_brand, ' ', i.i_category) AS brand_category,
    i.i_item_desc AS item_desc,
    p.p_promo_name AS promo_name
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  WHERE regexp_like(i.i_product_name, '.*Premium.*')
    AND p.p_promo_name LIKE '%Holiday%'
)
SELECT
  sales_year,
  category,
  SUM(sales_amount) AS total_sales,
  SUM(profit_amount) AS total_profit,
  CASE WHEN SUM(profit_amount) > 10000 THEN 'HIGH' ELSE 'LOW' END AS profit_level,
  COUNT(DISTINCT brand_category) AS distinct_brand_categories
FROM sales_union
GROUP BY ROLLUP (sales_year, category)
ORDER BY sales_year DESC NULLS LAST, category
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
