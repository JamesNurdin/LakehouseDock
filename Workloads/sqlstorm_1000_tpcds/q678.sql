WITH sales AS (
  SELECT
    ws.ws_sold_date_sk,
    ws.ws_order_number,
    ws.ws_item_sk,
    ws.ws_net_paid,
    d.d_year,
    d.d_date,
    c.c_first_name,
    c.c_last_name,
    c.c_email_address,
    i.i_product_name,
    i.i_item_desc,
    wp.wp_url,
    we.web_name AS site_name
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
),
ranked AS (
  SELECT
    d_year,
    lower(concat(c_first_name, ' ', c_last_name)) AS lower_customer_name,
    substr(i_product_name, 1, 15) AS product_name_prefix,
    length(i_product_name) AS product_name_length,
    split_part(c_email_address, '@', 2) AS email_domain,
    regexp_extract(split_part(c_email_address, '@', 2), '\\.([a-z]{2,})$', 1) AS email_tld,
    reverse(c_email_address) AS reversed_email,
    replace(wp_url, 'https://', '') AS url_no_scheme,
    regexp_extract(wp_url, '://([^/]+)/', 1) AS url_host,
    concat('ORD', CAST(ws_order_number AS varchar), '-', lpad(CAST(ws_item_sk AS varchar), 6, '0')) AS order_item_key,
    date_format(d_date, '%Y-%m-%d') AS sold_date_str,
    substr(i_item_desc, 1, 30) AS item_desc_snippet,
    regexp_replace(i_item_desc, '[^A-Za-z0-9 ]', '') AS item_desc_alphanum,
    translate(i_item_desc, 'aeiou', 'AEIOU') AS item_desc_vowel_uppercase,
    ws_net_paid,
    row_number() OVER (PARTITION BY d_year ORDER BY ws_net_paid DESC) AS rn
  FROM sales
)
SELECT
  d_year,
  lower_customer_name,
  product_name_prefix,
  product_name_length,
  email_domain,
  email_tld,
  reversed_email,
  url_no_scheme,
  url_host,
  order_item_key,
  sold_date_str,
  item_desc_snippet,
  item_desc_alphanum,
  item_desc_vowel_uppercase,
  ws_net_paid
FROM ranked
WHERE rn <= 10
ORDER BY d_year, rn
