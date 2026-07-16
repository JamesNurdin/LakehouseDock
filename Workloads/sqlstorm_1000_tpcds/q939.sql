SELECT
  s.s_store_id,
  s.s_store_name,
  lower(trim(s.s_store_name)) AS store_name_lower_trim,
  concat_ws(', ', s.s_street_number, s.s_street_name, s.s_city, s.s_state, s.s_zip) AS store_full_address,
  length(s.s_store_name) AS store_name_len,
  position(' ' IN s.s_store_name) AS first_space_pos,
  reverse(upper(s.s_manager)) AS rev_up_manager,
  substring(s.s_zip, 1, 3) AS zip_prefix,
  regexp_replace(s.s_zip, '[^0-9]', '') AS zip_digits,
  lower(trim(concat_ws(' ', c.c_first_name, c.c_last_name))) AS customer_full_name_lower,
  length(c.c_email_address) AS email_len,
  regexp_extract(c.c_email_address, '@(.+)$', 1) AS email_domain,
  replace(lower(i.i_product_name), ' ', '-') AS product_name_slug,
  substring(i.i_item_desc, 1, 50) AS item_desc_snippet,
  regexp_replace(i.i_item_desc, '[^A-Za-z0-9 ]', '') AS item_desc_alnum,
  cardinality(split(i.i_product_name, ' ')) AS product_name_word_count,
  array_join(split(i.i_product_name, ' '), '|') AS product_name_piped,
  lower(i.i_color) AS color_lower,
  upper(i.i_brand) AS brand_upper,
  concat_ws(' - ', i.i_brand, i.i_product_name) AS brand_product_concat,
  lower(ca.ca_city) AS cust_city_lower,
  concat_ws(' ', ca.ca_street_number, ca.ca_street_name, ca.ca_city, ca.ca_state, ca.ca_zip) AS cust_address,
  length(ca.ca_zip) AS ca_zip_len,
  regexp_like(c.c_email_address, '^.*@.*\\.com$') AS is_com_email,
  sum(ss.ss_net_profit) AS total_net_profit,
  sum(ss.ss_quantity) AS total_quantity,
  count(distinct ss.ss_ticket_number) AS unique_tickets,
  max(d.d_date) AS latest_date,
  min(d.d_date) AS earliest_date
FROM store s
JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE s.s_country = 'United States'
  AND regexp_like(s.s_store_name, '(?i)store')
GROUP BY
  s.s_store_id,
  s.s_store_name,
  s.s_street_number,
  s.s_street_name,
  s.s_city,
  s.s_state,
  s.s_zip,
  s.s_manager,
  c.c_first_name,
  c.c_last_name,
  c.c_email_address,
  i.i_product_name,
  i.i_item_desc,
  i.i_color,
  i.i_brand,
  ca.ca_city,
  ca.ca_street_number,
  ca.ca_street_name,
  ca.ca_state,
  ca.ca_zip
