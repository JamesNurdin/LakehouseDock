WITH combined_sales AS (
  SELECT
    i.i_brand,
    i.i_category,
    i.i_color,
    i.i_units,
    i.i_formulation,
    regexp_extract(i.i_formulation, '([0-9]+)', 1) AS formulation_num_part,
    regexp_extract(i.i_formulation, '([a-z]+)', 1) AS formulation_alpha_part,
    concat(i.i_brand, '-', i.i_category) AS brand_category,
    substr(i.i_formulation, 1, 5) AS formulation_prefix,
    cs.cs_net_paid_inc_ship AS net_paid,
    cs.cs_ext_discount_amt AS discount_amt,
    cs.cs_quantity AS quantity,
    'catalog' AS sales_channel
  FROM catalog_sales cs
  JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
  WHERE regexp_like(i.i_formulation, '[0-9]{2,}[a-z]+')
    AND i.i_units LIKE 'Box%'
  UNION ALL
  SELECT
    i.i_brand,
    i.i_category,
    i.i_color,
    i.i_units,
    i.i_formulation,
    regexp_extract(i.i_formulation, '([0-9]+)', 1) AS formulation_num_part,
    regexp_extract(i.i_formulation, '([a-z]+)', 1) AS formulation_alpha_part,
    concat(i.i_brand, '-', i.i_category) AS brand_category,
    substr(i.i_formulation, 1, 5) AS formulation_prefix,
    ss.ss_net_paid AS net_paid,
    ss.ss_ext_discount_amt AS discount_amt,
    ss.ss_quantity AS quantity,
    'store' AS sales_channel
  FROM store_sales ss
  JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
  WHERE regexp_like(i.i_formulation, '[0-9]{2,}[a-z]+')
    AND i.i_units LIKE 'Box%'
)
SELECT
  i_brand,
  i_category,
  i_color,
  formulation_num_part,
  formulation_alpha_part,
  brand_category,
  formulation_prefix,
  sales_channel,
  SUM(net_paid) AS total_net_paid,
  SUM(discount_amt) AS total_discount,
  SUM(quantity) AS total_quantity
FROM combined_sales
GROUP BY CUBE(
  i_brand,
  i_category,
  i_color,
  formulation_num_part,
  formulation_alpha_part,
  brand_category,
  formulation_prefix,
  sales_channel
)
ORDER BY total_net_paid DESC
LIMIT 100
