WITH sales_str AS (
   SELECT
      c.c_customer_id,
      d.d_year,
      lower(c.c_email_address) AS email_lower,
      concat_ws(' ', c.c_salutation, c.c_first_name, c.c_last_name) AS full_name,
      concat_ws(', ', ca.ca_street_number, ca.ca_street_name, ca.ca_city, ca.ca_state, ca.ca_zip) AS full_address,
      regexp_replace(lower(c.c_email_address), '[^a-z0-9]', '') AS email_alphanum,
      replace(c.c_preferred_cust_flag, 'Y', 'Yes') AS pref_cust_flag,
      i.i_product_name,
      i.i_item_desc AS i_item_desc,
      regexp_extract(i.i_item_desc, '(\\d+)', 1) AS first_number_in_desc,
      translate(i.i_product_name, 'AEIOUaeiou', '') AS product_no_vowels,
      wp.wp_url,
      split_part(wp.wp_url, '/', 3) AS domain_part,
      p.p_promo_name,
      p.p_channel_email,
      ws.ws_net_paid,
      ws.ws_order_number
   FROM customer c
   JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
   JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
   JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   WHERE c.c_preferred_cust_flag = 'Y'
)
SELECT
   c_customer_id,
   max(full_name) AS full_name,
   max(email_lower) AS email_lower,
   max(email_alphanum) AS email_alphanum,
   max(pref_cust_flag) AS pref_cust_flag,
   max(full_address) AS full_address,
   length(max(full_name)) AS name_len,
   length(max(full_address)) AS address_len,
   min(d_year) AS first_year,
   max(d_year) AS last_year,
   sum(ws_net_paid) AS total_spent,
   count(DISTINCT ws_order_number) AS distinct_orders,
   array_join(array_agg(DISTINCT p_promo_name), ', ') AS promo_names
FROM sales_str
GROUP BY c_customer_id
