WITH agg_returns AS (
  SELECT
    cr_item_sk,
    SUM(cr_return_amount) AS total_return_amount,
    COUNT(*) AS return_cnt,
    SUM(cr_return_quantity) AS total_qty
  FROM catalog_returns
  WHERE cr_return_amount > 100
  GROUP BY cr_item_sk
),
item_filtered AS (
  SELECT
    i_item_sk,
    i_item_id,
    i_product_name,
    i_brand,
    i_category,
    i_color,
    CONCAT(i_brand, ' - ', i_product_name) AS brand_product,
    REGEXP_EXTRACT(i_item_id, '(\\d+)$') AS item_id_num,
    CASE
      WHEN REGEXP_LIKE(i_color, '^s') THEN 'StartsWithS'
      ELSE 'Other'
    END AS color_group
  FROM item
  WHERE REGEXP_LIKE(i_color, '^(s|r)')
    AND i_product_name LIKE '%s%'
),
discount_levels AS (
  SELECT 1 AS lvl UNION ALL SELECT 2 UNION ALL SELECT 3
)
SELECT
  p.p_promo_id,
  p.p_promo_name,
  REGEXP_EXTRACT(p.p_promo_id, '([A-Z]+)') AS promo_prefix,
  i.brand_product,
  i.color_group,
  agg.total_return_amount,
  agg.return_cnt,
  agg.total_qty,
  d.lvl AS discount_tier,
  RANK() OVER (PARTITION BY i.i_category ORDER BY agg.total_return_amount DESC) AS category_rank,
  ROW_NUMBER() OVER (ORDER BY agg.total_return_amount DESC) AS seq_num
FROM item_filtered i
LEFT JOIN agg_returns agg ON agg.cr_item_sk = i.i_item_sk
RIGHT OUTER JOIN promotion p ON p.p_item_sk = i.i_item_sk
CROSS JOIN discount_levels d
WHERE p.p_purpose LIKE 'U%'
  AND REGEXP_LIKE(p.p_promo_name, '^[A-Z]{3}')
ORDER BY agg.total_return_amount DESC NULLS LAST, p.p_promo_id
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
