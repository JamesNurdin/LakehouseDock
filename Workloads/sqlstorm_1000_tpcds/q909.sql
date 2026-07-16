SELECT
  cc.cc_call_center_id,
  lower(cc.cc_manager) AS manager_lc,
  replace(trim(cc.cc_city), ' ', '_') AS city_normalized,
  cp.cp_catalog_page_id,
  regexp_replace(cp.cp_description, '[^A-Za-z0-9 ]', '') AS clean_desc,
  length(regexp_replace(cp.cp_description, '[^A-Za-z0-9 ]', '')) AS clean_desc_len,
  cardinality(split(cp.cp_description, ' ')) AS desc_word_cnt,
  i.i_item_id,
  lower(i.i_color) AS color_lc,
  substring(i.i_product_name, 1, 10) AS product_name_prefix,
  concat_ws(' ', c.c_first_name, c.c_last_name) AS cust_full_name,
  lower(c.c_email_address) AS email_lc,
  regexp_extract(c.c_email_address, '@([^.]*)', 1) AS email_domain,
  sum(cs.cs_ext_sales_price) AS total_sales,
  sum(cs.cs_quantity) AS total_quantity,
  count(*) AS sales_cnt
FROM catalog_sales cs
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
WHERE cs.cs_sold_date_sk BETWEEN 2450815 AND 2450900
  AND lower(cc.cc_manager) LIKE '%john%'
  AND regexp_like(i.i_item_desc, '\\bPremium\\b')
GROUP BY
  cc.cc_call_center_id,
  lower(cc.cc_manager),
  replace(trim(cc.cc_city), ' ', '_'),
  cp.cp_catalog_page_id,
  regexp_replace(cp.cp_description, '[^A-Za-z0-9 ]', ''),
  length(regexp_replace(cp.cp_description, '[^A-Za-z0-9 ]', '')),
  cardinality(split(cp.cp_description, ' ')),
  i.i_item_id,
  lower(i.i_color),
  substring(i.i_product_name, 1, 10),
  concat_ws(' ', c.c_first_name, c.c_last_name),
  lower(c.c_email_address),
  regexp_extract(c.c_email_address, '@([^.]*)', 1)
HAVING sum(cs.cs_ext_sales_price) > 10000
ORDER BY total_sales DESC
LIMIT 100
