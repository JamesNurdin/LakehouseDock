WITH cs_data AS (
  SELECT cs.cs_sold_date_sk,
         cs.cs_order_number,
         cs.cs_call_center_sk,
         cs.cs_bill_customer_sk,
         cs.cs_item_sk,
         cs.cs_catalog_page_sk
  FROM catalog_sales cs
),
call_center_strings AS (
  SELECT cc.cc_call_center_sk,
         lower(cc.cc_name) AS lc_cc_name,
         regexp_replace(cc.cc_manager, '\\s+', '_') AS manager_underscored,
         trim(cc.cc_city) AS trimmed_city,
         length(cc.cc_name) AS cc_name_len,
         length(regexp_replace(cc.cc_name, '[^A-Za-z]', '')) AS cc_name_alpha_len,
         concat(cc.cc_name, ' - ', cc.cc_state) AS full_center_desc,
         regexp_extract(cc.cc_hours, '(\\d{2}:\\d{2})', 1) AS open_time
  FROM call_center cc
),
customer_strings AS (
  SELECT c.c_customer_sk,
         lower(c.c_first_name) AS first_name_lc,
         lower(c.c_last_name) AS last_name_lc,
         concat_ws(' ', c.c_first_name, c.c_last_name) AS full_name,
         split(c.c_email_address, '@')[2] AS email_domain,
         length(c.c_email_address) AS email_len,
         regexp_replace(c.c_email_address, '[^@]+@', '') AS email_suffix,
         regexp_like(c.c_email_address, '@.*\\.com$') AS is_com_email
  FROM customer c
),
item_strings AS (
  SELECT i.i_item_sk,
         i.i_product_name,
         lower(i.i_product_name) AS product_name_lc,
         regexp_replace(i.i_product_name, '[0-9]', '') AS product_name_no_digits,
         length(i.i_product_name) AS product_name_len,
         length(regexp_replace(i.i_product_name, '[0-9]', '')) AS product_name_no_digits_len,
         regexp_like(i.i_product_name, '\\d+$') AS product_name_ends_digit,
         concat(i.i_product_name, ' ', i.i_color, ' ', i.i_size) AS full_product_desc
  FROM item i
),
web_page_strings AS (
  SELECT wp.wp_web_page_sk,
         wp.wp_url,
         split(wp.wp_url, '/')[3] AS url_domain,
         regexp_extract(wp.wp_url, '\\.([a-z]{2,})$', 1) AS url_tld,
         replace(wp.wp_url, 'http://', '') AS url_no_http,
         length(wp.wp_url) AS url_len,
         lower(wp.wp_url) AS url_lc
  FROM web_page wp
),
joined_data AS (
  SELECT
    cs.cs_sold_date_sk,
    cs.cs_order_number,
    cs.cs_call_center_sk,
    cs.cs_bill_customer_sk,
    cs.cs_item_sk,
    d.d_year,
    d.d_month_seq,
    cc.lc_cc_name,
    cc.manager_underscored,
    cc.trimmed_city,
    cc.full_center_desc,
    cc.cc_name_len,
    cc.cc_name_alpha_len,
    cust.first_name_lc,
    cust.last_name_lc,
    cust.full_name,
    cust.email_domain,
    cust.email_len,
    item.product_name_lc,
    item.product_name_no_digits,
    item.product_name_len,
    item.product_name_no_digits_len,
    item.product_name_ends_digit,
    item.full_product_desc,
    wp.url_domain,
    wp.url_tld,
    wp.url_len
  FROM cs_data cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  LEFT JOIN call_center_strings cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  LEFT JOIN customer_strings cust ON cs.cs_bill_customer_sk = cust.c_customer_sk
  LEFT JOIN item_strings item ON cs.cs_item_sk = item.i_item_sk
  LEFT JOIN web_page_strings wp ON cs.cs_catalog_page_sk = wp.wp_web_page_sk
)
SELECT
  concat(CAST(d_year AS varchar), '-', CAST(d_month_seq AS varchar)) AS year_month,
  d_year,
  d_month_seq,
  COUNT(DISTINCT cs_order_number) AS total_orders,
  SUM(CASE WHEN manager_underscored IS NOT NULL THEN 1 ELSE 0 END) AS total_managers,
  AVG(cc_name_len) AS avg_cc_name_len,
  MAX(cc_name_alpha_len) AS max_cc_name_alpha_len,
  COUNT(DISTINCT email_domain) AS distinct_email_domains,
  AVG(email_len) AS avg_email_len,
  COUNT(DISTINCT url_domain) AS distinct_url_domains,
  COUNT(DISTINCT url_tld) AS distinct_url_tlds,
  AVG(product_name_len) AS avg_product_name_len,
  AVG(product_name_no_digits_len) AS avg_product_name_no_digits_len,
  SUM(CASE WHEN product_name_ends_digit THEN 1 ELSE 0 END) AS products_ending_digit_cnt,
  COUNT(DISTINCT full_name) AS distinct_customers,
  COUNT(DISTINCT full_product_desc) AS distinct_product_descs,
  SUM(url_len) AS total_url_characters
FROM joined_data
GROUP BY d_year, d_month_seq
ORDER BY d_year, d_month_seq
