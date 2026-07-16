WITH cat_data AS (
  SELECT
    'catalog' AS sale_type,
    d.d_year,
    concat_ws(' | ',
      cc.cc_name,
      cc.cc_manager,
      cp.cp_type,
      cp.cp_description,
      i.i_product_name,
      i.i_item_desc,
      i.i_color,
      i.i_brand,
      c.c_first_name,
      c.c_last_name,
      c.c_email_address) AS detail_str
  FROM catalog_sales cs
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN date_dim d ON d.d_date_sk = cs.cs_sold_date_sk
  JOIN catalog_page cp ON cp.cp_catalog_page_sk = cs.cs_catalog_page_sk
  JOIN item i ON i.i_item_sk = cs.cs_item_sk
  JOIN customer c ON c.c_customer_sk = cs.cs_bill_customer_sk
),
store_data AS (
  SELECT
    'store' AS sale_type,
    d.d_year,
    concat_ws(' | ',
      s.s_store_name,
      s.s_city,
      s.s_state,
      i.i_product_name,
      i.i_item_desc,
      i.i_color,
      i.i_brand,
      c.c_first_name,
      c.c_last_name,
      c.c_email_address) AS detail_str
  FROM store_sales ss
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN date_dim d ON d.d_date_sk = ss.ss_sold_date_sk
  JOIN item i ON i.i_item_sk = ss.ss_item_sk
  JOIN customer c ON c.c_customer_sk = ss.ss_customer_sk
),
web_data AS (
  SELECT
    'web' AS sale_type,
    d.d_year,
    concat_ws(' | ',
      wp.wp_type,
      wp.wp_url,
      i.i_product_name,
      i.i_item_desc,
      i.i_color,
      i.i_brand,
      c.c_first_name,
      c.c_last_name,
      c.c_email_address) AS detail_str
  FROM web_sales ws
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN date_dim d ON d.d_date_sk = ws.ws_sold_date_sk
  JOIN item i ON i.i_item_sk = ws.ws_item_sk
  JOIN customer c ON c.c_customer_sk = ws.ws_bill_customer_sk
),
combined AS (
  SELECT * FROM cat_data
  UNION ALL
  SELECT * FROM store_data
  UNION ALL
  SELECT * FROM web_data
),
enriched AS (
  SELECT
    sale_type,
    d_year,
    detail_str,
    length(detail_str) AS detail_len,
    cardinality(regexp_extract_all(lower(detail_str), '[aeiou]')) AS vowel_cnt,
    cardinality(regexp_extract_all(detail_str, '[0-9]')) AS digit_cnt,
    cardinality(split(detail_str, ' +')) AS word_cnt,
    cardinality(regexp_extract_all(lower(detail_str), '[bcdfghjklmnpqrstvwxyz]')) AS consonant_cnt,
    cardinality(regexp_extract_all(detail_str, '[^A-Za-z0-9 ]')) AS special_char_cnt,
    substring(detail_str, 1, 10) AS prefix_10,
    substring(detail_str, length(detail_str) - 9, 10) AS suffix_10,
    replace(detail_str, ' ', '_') AS underscore_detail,
    CASE WHEN regexp_like(detail_str, '[A-Z]{3}') THEN 1 ELSE 0 END AS has_three_consecutive_caps,
    ROW_NUMBER() OVER (PARTITION BY sale_type, d_year ORDER BY length(detail_str) DESC) AS rn
  FROM combined
  WHERE d_year BETWEEN 1998 AND 2002
)
SELECT
  sale_type,
  d_year,
  detail_str,
  detail_len,
  vowel_cnt,
  digit_cnt,
  word_cnt,
  consonant_cnt,
  special_char_cnt,
  prefix_10,
  suffix_10,
  underscore_detail,
  has_three_consecutive_caps
FROM enriched
WHERE rn = 1
ORDER BY d_year DESC, sale_type
LIMIT 100
