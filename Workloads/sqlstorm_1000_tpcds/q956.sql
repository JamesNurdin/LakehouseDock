WITH enriched AS (
 SELECT
  c.c_customer_id,
  concat_ws(' ', c.c_first_name, c.c_last_name) AS full_name,
  lower(c.c_email_address) AS email_lower,
  regexp_extract(c.c_email_address, '@(.+)$', 1) AS email_domain,
  length(c.c_email_address) AS email_len,
  cs.cs_order_number,
  cs.cs_quantity,
  cs.cs_net_paid,
  d.d_year,
  d.d_quarter_name,
  i.i_item_id,
  i.i_item_desc,
  length(i.i_item_desc) AS desc_len,
  regexp_replace(i.i_item_desc, '[^A-Za-z0-9 ]', '') AS desc_clean,
  split(i.i_item_desc, ' ') AS desc_words,
  CASE WHEN regexp_like(i.i_item_desc, '(?i)premium') THEN 'Y' ELSE 'N' END AS is_premium,
  cc.cc_name,
  lower(cc.cc_manager) AS manager_lower,
  cc.cc_hours,
  regexp_extract(cc.cc_hours, '(\\d{2}:\\d{2})-(\\d{2}:\\d{2})', 1) AS open_time,
  regexp_extract(cc.cc_hours, '(\\d{2}:\\d{2})-(\\d{2}:\\d{2})', 2) AS close_time,
  cp.cp_description,
  lower(cp.cp_description) AS cp_desc_lower,
  length(cp.cp_description) AS cp_desc_len,
  regexp_extract(cp.cp_description, '(\\w+)', 1) AS cp_first_word
 FROM catalog_sales cs
 JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
 JOIN item i ON cs.cs_item_sk = i.i_item_sk
 JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
 JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
 JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
 WHERE cs.cs_quantity > 0
)
SELECT
  email_domain,
  d_quarter_name,
  count(*) AS total_orders,
  sum(cs_quantity) AS total_quantity,
  avg(cs_net_paid) AS avg_net_paid,
  avg(email_len) AS avg_email_len,
  max(email_len) AS max_email_len,
  min(email_len) AS min_email_len,
  approx_distinct(full_name) AS distinct_customers,
  array_join(array_agg(DISTINCT lower(cc_name)), ', ') AS call_center_names,
  concat_ws('_', email_domain, substring(min(cc_name), 1, 3), d_quarter_name) AS composite_key,
  max(open_time) AS earliest_open_time,
  max(close_time) AS latest_close_time,
  max(CASE WHEN is_premium = 'Y' THEN 1 ELSE 0 END) AS any_premium_item,
  max(desc_len) AS max_desc_len,
  approx_percentile(desc_len, 0.5) AS median_desc_len,
  array_join(array_agg(DISTINCT cp_first_word), ', ') AS cp_first_words,
  array_join(array_agg(DISTINCT replace(desc_clean, ' ', '_')), ', ') AS cleaned_descs_underscored
FROM enriched
GROUP BY email_domain, d_quarter_name
HAVING count(*) > 100
ORDER BY total_orders DESC
LIMIT 50
