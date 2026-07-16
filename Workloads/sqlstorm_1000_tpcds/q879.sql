WITH page_str AS (
  SELECT
    wp.wp_web_page_sk,
    wp.wp_web_page_id,
    wp.wp_url,
    regexp_extract(wp.wp_url, 'https?://([^/]+)/', 1) AS domain,
    lower(regexp_replace(regexp_extract(wp.wp_url, 'https?://([^/]+)/', 1), '[^a-z0-9]', '_')) AS normalized_domain,
    length(wp.wp_url) AS url_len,
    reverse(wp.wp_url) AS reversed_url,
    regexp_extract(wp.wp_url, '^https?://[^/]+/(.*)', 1) AS url_path,
    cardinality(split(regexp_extract(wp.wp_url, '^https?://[^/]+/(.*)', 1), '/')) AS path_segments,
    lower(regexp_replace(wp.wp_url, '[^a-z0-9]', '_')) AS sanitized_url
  FROM web_page wp
),
sales_enriched AS (
  SELECT
    ps.wp_web_page_id,
    ps.domain,
    ps.normalized_domain,
    ps.url_len,
    ps.path_segments,
    ps.sanitized_url,
    ps.reversed_url,
    ws.ws_net_paid,
    ws.ws_ext_discount_amt,
    ws.ws_order_number,
    c.c_first_name,
    c.c_last_name,
    i.i_product_name,
    ca.ca_street_number,
    ca.ca_street_name,
    ca.ca_street_type,
    ca.ca_suite_number,
    ca.ca_city,
    ca.ca_state,
    ca.ca_zip
  FROM page_str ps
  JOIN web_sales ws ON ps.wp_web_page_sk = ws.ws_web_page_sk
  JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2002
)
SELECT
  wp_web_page_id,
  domain,
  normalized_domain,
  url_len,
  path_segments,
  sanitized_url,
  concat(sanitized_url, '_', normalized_domain) AS url_key,
  max(reversed_url) AS reversed_url,
  sum(ws_net_paid) AS total_net_paid,
  sum(ws_ext_discount_amt) AS total_discount,
  count(DISTINCT ws_order_number) AS order_count,
  approx_distinct(ws_order_number) AS approx_order_count,
  max(concat_ws('_', lower(c_first_name), lower(c_last_name))) AS cust_name_key,
  max(length(i_product_name)) AS max_product_name_len,
  max(substring(i_product_name, 1, 10)) AS product_name_prefix,
  max(replace(i_product_name, ' ', '-')) AS product_name_dash,
  max(array_join(split(i_product_name, ' '), '|')) AS product_name_pipes,
  max(concat_ws(' ', ca_street_number, ca_street_name, ca_street_type, coalesce(ca_suite_number, ''), ca_city, ca_state, ca_zip)) AS full_address,
  max(length(concat_ws(' ', ca_street_number, ca_street_name, ca_street_type, coalesce(ca_suite_number, ''), ca_city, ca_state, ca_zip))) AS address_len,
  max(regexp_replace(concat_ws(' ', ca_street_number, ca_street_name, ca_street_type, ca_city, ca_state, ca_zip), '[^a-z0-9]', '_')) AS address_normalized
FROM sales_enriched
GROUP BY
  wp_web_page_id,
  domain,
  normalized_domain,
  url_len,
  path_segments,
  sanitized_url
ORDER BY total_net_paid DESC
LIMIT 100
