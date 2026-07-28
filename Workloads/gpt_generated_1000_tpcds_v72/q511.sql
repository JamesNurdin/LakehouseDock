WITH filtered_promos AS (
  SELECT p_promo_sk, p_promo_name, p_item_sk
  FROM promotion
  WHERE regexp_like(p_channel_details, 'common')
    AND p_channel_catalog = 'N'
)
SELECT
  i.i_category,
  i.i_category_id,
  SUM(cs.cs_ext_sales_price) AS total_sales,
  SUM(cs.cs_quantity) AS total_units,
  CASE WHEN SUM(cs.cs_ext_sales_price) > 100000 THEN 'High' ELSE 'Low' END AS sales_bucket,
  ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY SUM(cs.cs_ext_sales_price) DESC) AS sales_rank,
  CONCAT(i.i_category, '-', m.first_word) AS category_manufact_key
FROM filtered_promos fp
JOIN catalog_sales cs
  ON cs.cs_promo_sk = fp.p_promo_sk
JOIN item i
  ON i.i_item_sk = cs.cs_item_sk
JOIN date_dim d
  ON cs.cs_sold_date_sk = d.d_date_sk
CROSS JOIN LATERAL (
  SELECT regexp_extract(i.i_manufact, '([A-Za-z]+)') AS first_word
) AS m
WHERE d.d_year = 2001
  AND i.i_manufact LIKE '%st%'
GROUP BY i.i_category, i.i_category_id, m.first_word
ORDER BY total_sales DESC
LIMIT 100
