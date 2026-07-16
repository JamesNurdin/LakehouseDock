WITH sales_str AS (
  SELECT
    d.d_year,
    i.i_item_sk,
    i.i_product_name,
    cc.cc_name,
    cs.cs_quantity,
    cs.cs_ext_sales_price,
    cs.cs_ext_discount_amt,
    cs.cs_ext_sales_price - cs.cs_ext_discount_amt AS net_sales,
    lower(i.i_product_name) AS lower_prod_name,
    regexp_replace(i.i_product_name, '[^A-Za-z0-9]', '') AS alnum_prod_name,
    length(i.i_product_name) AS prod_name_len,
    cardinality(split(i.i_product_name, '\\s+')) AS prod_word_cnt,
    length(regexp_replace(lower(i.i_product_name), '[^aeiou]', '')) AS vowel_cnt,
    reverse(i.i_product_name) AS rev_prod_name,
    replace(replace(replace(i.i_product_name, 'a', '@'), 'e', '3'), 'i', '1') AS leet_prod_name,
    concat_ws(' ', i.i_product_name, p.p_promo_name, cc.cc_name) AS combined_str,
    length(concat_ws(' ', i.i_product_name, p.p_promo_name, cc.cc_name)) AS combined_len,
    regexp_extract(i.i_product_name, '([A-Z][a-z]+)', 1) AS first_cap_word,
    format('%s-%s-%s', i.i_brand, i.i_class, i.i_category) AS brand_class_category,
    trim(i.i_product_name) AS trimmed_name,
    ltrim(rtrim(i.i_product_name)) AS both_trimmed,
    substr(i.i_product_name, 1, 5) AS first5,
    substr(i.i_product_name, -5) AS last5,
    concat_ws('_', lower(i.i_category), lower(i.i_brand), lower(cc.cc_name)) AS composite_key,
    cardinality(split(p.p_promo_name, '\\s+')) AS promo_word_cnt,
    length(regexp_replace(i.i_product_name, '[^A-Z]', '')) AS uppercase_cnt,
    length(regexp_replace(i.i_product_name, '[^a-z]', '')) AS lowercase_cnt,
    length(i.i_product_name) - length(regexp_replace(i.i_product_name, '[0-9]', '')) AS digit_cnt,
    length(i.i_product_name) - length(regexp_replace(i.i_product_name, '[^\\s]', '')) AS space_cnt
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  WHERE d.d_year BETWEEN 1999 AND 2002
)
SELECT
  d_year,
  i_item_sk,
  first5,
  last5,
  lower_prod_name,
  alnum_prod_name,
  leet_prod_name,
  rev_prod_name,
  prod_name_len,
  prod_word_cnt,
  vowel_cnt,
  uppercase_cnt,
  lowercase_cnt,
  digit_cnt,
  space_cnt,
  combined_len,
  composite_key,
  brand_class_category,
  total_sales,
  total_qty,
  row_number() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank
FROM (
  SELECT
    d_year,
    i_item_sk,
    sum(net_sales) AS total_sales,
    sum(cs_quantity) AS total_qty,
    max(first5) AS first5,
    max(last5) AS last5,
    max(lower_prod_name) AS lower_prod_name,
    max(alnum_prod_name) AS alnum_prod_name,
    max(leet_prod_name) AS leet_prod_name,
    max(rev_prod_name) AS rev_prod_name,
    max(prod_name_len) AS prod_name_len,
    max(prod_word_cnt) AS prod_word_cnt,
    max(vowel_cnt) AS vowel_cnt,
    max(uppercase_cnt) AS uppercase_cnt,
    max(lowercase_cnt) AS lowercase_cnt,
    max(digit_cnt) AS digit_cnt,
    max(space_cnt) AS space_cnt,
    max(combined_len) AS combined_len,
    max(composite_key) AS composite_key,
    max(brand_class_category) AS brand_class_category
  FROM sales_str
  GROUP BY d_year, i_item_sk
) t
ORDER BY d_year, sales_rank
LIMIT 100
