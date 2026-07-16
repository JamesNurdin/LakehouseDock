WITH sales AS (
  SELECT ss.ss_customer_sk AS customer_sk,
         ss.ss_item_sk AS item_sk,
         ss.ss_net_paid AS net_paid,
         ss.ss_sold_date_sk AS sold_date_sk,
         'store' AS channel
  FROM store_sales ss
  UNION ALL
  SELECT cs.cs_bill_customer_sk AS customer_sk,
         cs.cs_item_sk AS item_sk,
         cs.cs_net_paid AS net_paid,
         cs.cs_sold_date_sk AS sold_date_sk,
         'catalog' AS channel
  FROM catalog_sales cs
  UNION ALL
  SELECT ws.ws_bill_customer_sk AS customer_sk,
         ws.ws_item_sk AS item_sk,
         ws.ws_net_paid AS net_paid,
         ws.ws_sold_date_sk AS sold_date_sk,
         'web' AS channel
  FROM web_sales ws
),
customer_info AS (
  SELECT
    c.c_customer_sk,
    c.c_customer_id,
    concat_ws(' ', c.c_salutation, c.c_first_name, c.c_last_name) AS full_name,
    lower(trim(c.c_email_address)) AS email,
    concat('C', CAST(c.c_customer_sk AS varchar), '-', CAST(c.c_birth_year AS varchar)) AS cust_key,
    ca.ca_address_sk,
    concat_ws(', ', ca.ca_street_number, ca.ca_street_name, ca.ca_city, ca.ca_state, ca.ca_zip) AS address,
    regexp_replace(concat_ws(', ', ca.ca_street_number, ca.ca_street_name, ca.ca_city, ca.ca_state, ca.ca_zip), '\\s+', ' ') AS clean_address,
    ca.ca_state,
    ca.ca_country
  FROM customer c
  LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT
  ci.c_customer_id,
  ci.full_name,
  ci.email,
  ci.cust_key,
  ci.clean_address,
  ci.ca_state,
  ci.ca_country,
  array_join(array_agg(DISTINCT i.i_category), '|') AS categories,
  array_join(array_agg(DISTINCT lower(i.i_product_name)), ',') AS product_names_lower,
  regexp_replace(array_join(array_agg(DISTINCT regexp_replace(i.i_item_desc, '[^A-Za-z0-9 ]', '')), ' '), '\\s+', ' ') AS cleaned_item_descs,
  sum(s.net_paid) AS total_net_paid,
  count(*) AS total_transactions,
  max(s.sold_date_sk) AS latest_sold_date_sk,
  concat_ws(' | ', ci.ca_state, ci.ca_country, concat('Channels:', array_join(array_agg(DISTINCT s.channel), ','))) AS misc_info,
  length(array_join(array_agg(DISTINCT i.i_product_name), ',')) AS total_product_name_chars,
  substr(array_join(array_agg(DISTINCT i.i_product_name), ','), 1, 100) AS product_name_preview,
  concat_ws('::', CAST(count(DISTINCT s.channel) AS varchar), CAST(count(DISTINCT i.i_item_sk) AS varchar)) AS channel_item_counts
FROM sales s
JOIN customer_info ci ON s.customer_sk = ci.c_customer_sk
JOIN item i ON s.item_sk = i.i_item_sk
GROUP BY ci.c_customer_id, ci.full_name, ci.email, ci.cust_key, ci.clean_address, ci.ca_state, ci.ca_country
ORDER BY total_net_paid DESC
LIMIT 10
