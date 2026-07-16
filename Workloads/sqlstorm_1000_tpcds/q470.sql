SELECT
  s.s_store_id,
  s.s_store_name,
  lower(regexp_replace(trim(s.s_city), '\\s+', '_')) AS city_normalized,
  concat_ws('_', lower(regexp_replace(trim(s.s_state), '\\s+', '_')), lower(regexp_replace(trim(s.s_country), '\\s+', '_'))) AS location_code,
  coalesce(s.s_manager, 'UNKNOWN') AS store_manager,
  substring(c.c_email_address, strpos(c.c_email_address, '@') + 1) AS email_domain,
  avg(length(c.c_customer_id)) AS avg_cust_id_len,
  regexp_replace(i.i_product_name, '[^A-Za-z0-9]', '') AS product_name_alnum,
  length(regexp_replace(i.i_product_name, '[^A-Za-z0-9]', '')) AS product_name_alnum_len,
  lower(split_part(i.i_product_name, ' ', 1)) AS product_first_word,
  substr(i.i_product_name, 1, 10) AS product_name_prefix,
  concat('store_', s.s_store_id, '_', date_format(td.d_date, '%Y-%m')) AS partition_key,
  sum(ss.ss_net_paid) AS total_net_paid,
  avg(ss.ss_ext_discount_amt) AS avg_discount,
  count(distinct ss.ss_ticket_number) AS distinct_tickets,
  count(*) AS sales_rows,
  max(length(i.i_product_name)) AS max_product_name_len,
  min(length(i.i_product_name)) AS min_product_name_len,
  approx_distinct(c.c_customer_id) AS approx_unique_customers,
  array_agg(distinct lower(regexp_replace(i.i_product_name, '\\s+', '_'))) FILTER (WHERE ss.ss_quantity > 10) AS high_quantity_products
FROM store_sales ss
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim td ON ss.ss_sold_date_sk = td.d_date_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
WHERE td.d_year = 2001
  AND regexp_like(lower(s.s_store_name), 'store')
  AND length(trim(s.s_zip)) = 5
  AND regexp_like(i.i_product_name, '^[A-Za-z].*[0-9]$')
GROUP BY
  s.s_store_id,
  s.s_store_name,
  lower(regexp_replace(trim(s.s_city), '\\s+', '_')),
  concat_ws('_', lower(regexp_replace(trim(s.s_state), '\\s+', '_')), lower(regexp_replace(trim(s.s_country), '\\s+', '_'))),
  coalesce(s.s_manager, 'UNKNOWN'),
  substring(c.c_email_address, strpos(c.c_email_address, '@') + 1),
  regexp_replace(i.i_product_name, '[^A-Za-z0-9]', ''),
  length(regexp_replace(i.i_product_name, '[^A-Za-z0-9]', '')),
  lower(split_part(i.i_product_name, ' ', 1)),
  substr(i.i_product_name, 1, 10),
  concat('store_', s.s_store_id, '_', date_format(td.d_date, '%Y-%m'))
ORDER BY total_net_paid DESC
LIMIT 100
