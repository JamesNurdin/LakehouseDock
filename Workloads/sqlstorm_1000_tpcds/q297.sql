SELECT
  d.d_date AS sale_date,
  s.s_store_id,
  s.s_city,
  COUNT(DISTINCT c.c_customer_sk) AS distinct_customers,
  SUM(ss.ss_net_paid) AS total_net_paid,
  array_join(array_sort(array_agg(DISTINCT lower(substr(c.c_first_name, 1, 1)))), '|') AS name_initials,
  array_join(array_agg(DISTINCT regexp_replace(regexp_replace(lower(i.i_product_name), '\\s+', '_'), '[^a-z0-9_]', '')), ',') AS norm_product_names,
  AVG(cardinality(regexp_split(regexp_replace(i.i_item_desc, '[^\\w\\s]', ''), '\\s+'))) AS avg_desc_word_count,
  array_agg(DISTINCT regexp_extract(i.i_item_id, '(\\d+)')) FILTER (WHERE regexp_extract(i.i_item_id, '(\\d+)') IS NOT NULL) AS extracted_item_numbers,
  reverse(ANY_VALUE(s.s_store_name)) AS reversed_store_name,
  length(concat_ws(' ', ANY_VALUE(s.s_street_number), ANY_VALUE(s.s_street_name), ANY_VALUE(s.s_street_type), ANY_VALUE(s.s_suite_number), ANY_VALUE(s.s_city), ANY_VALUE(s.s_state), ANY_VALUE(s.s_zip))) AS address_str_len,
  length(trim(ANY_VALUE(s.s_store_name))) - length(replace(trim(ANY_VALUE(s.s_store_name)), ' ', '')) AS store_name_space_count,
  (SELECT lower(regexp_replace(cc.cc_name, '\\W+', '')) FROM call_center cc ORDER BY cc.cc_call_center_sk LIMIT 1) AS normalized_call_center_name
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
WHERE d.d_year = 2000
GROUP BY d.d_date, s.s_store_id, s.s_city
ORDER BY total_net_paid DESC
LIMIT 100
