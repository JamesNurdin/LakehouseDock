WITH combined_sales AS (
   SELECT
     ss.ss_sold_date_sk AS sold_date_sk,
     ss.ss_customer_sk AS customer_sk,
     ss.ss_item_sk AS item_sk,
     ss.ss_net_paid AS net_paid,
     ss.ss_quantity AS quantity,
     'store' AS channel,
     ss.ss_promo_sk AS promo_sk,
     ss.ss_ticket_number AS ticket_number
   FROM store_sales ss
   UNION ALL
   SELECT
     ws.ws_sold_date_sk,
     ws.ws_bill_customer_sk,
     ws.ws_item_sk,
     ws.ws_net_paid,
     ws.ws_quantity,
     'web' AS channel,
     ws.ws_promo_sk,
     ws.ws_order_number
   FROM web_sales ws
),
customer_strings AS (
   SELECT
     c.c_customer_sk,
     c.c_customer_id,
     c.c_first_name,
     c.c_last_name,
     c.c_email_address,
     ca.ca_zip,
     CONCAT_WS('_', UPPER(c.c_last_name), LOWER(c.c_first_name)) AS name_upp_low,
     SPLIT_PART(c.c_email_address, '@', 2) AS email_domain,
     REVERSE(ca.ca_zip) AS rev_zip,
     REGEXP_REPLACE(c.c_last_name, '\\s+', '') AS last_name_nospace,
     REGEXP_REPLACE(c.c_email_address, '[^@]+@', '') AS email_domain_regex,
     REPLACE(c.c_first_name, 'a', '@') AS first_name_a_replace,
     SUBSTR(c.c_first_name, 1, 3) AS first_name_prefix,
     SUBSTR(c.c_last_name, -3) AS last_name_suffix,
     LENGTH(c.c_first_name) AS first_name_len,
     LENGTH(c.c_last_name) AS last_name_len,
     REGEXP_REPLACE(c.c_email_address, '[^A-Za-z0-9@.]', '') AS clean_email,
     CONCAT_WS('|', c.c_first_name, c.c_last_name, c.c_email_address) AS composite_field
   FROM customer c
   JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
item_strings AS (
   SELECT
     i.i_item_sk,
     i.i_product_name,
     i.i_item_desc,
     i.i_color,
     i.i_size,
     i.i_brand,
     LOWER(i.i_product_name) AS product_name_lower,
     REVERSE(i.i_product_name) AS product_name_reverse,
     REGEXP_REPLACE(i.i_product_name, '\\s+', '_') AS product_name_underscored,
     SUBSTR(i.i_item_desc, 1, 10) AS item_desc_prefix,
     LENGTH(i.i_item_desc) AS item_desc_len,
     CARDINALITY(SPLIT(i.i_item_desc, '\\s+')) AS item_desc_word_count,
     REGEXP_EXTRACT(i.i_item_desc, '(\\d+)', 1) AS first_number_in_desc
   FROM item i
),
promo_strings AS (
   SELECT
     p.p_promo_sk,
     p.p_promo_name,
     p.p_channel_details,
     REPLACE(LOWER(p.p_promo_name), ' ', '-') AS promo_name_slug,
     REGEXP_REPLACE(p.p_promo_name, '[^A-Za-z0-9]', '') AS promo_name_alnum,
     REVERSE(p.p_promo_name) AS promo_name_reverse,
     LENGTH(p.p_promo_name) AS promo_name_len,
     SUBSTRING(p.p_channel_details FROM 1 FOR 5) AS channel_detail_prefix
   FROM promotion p
),
sales_agg AS (
   SELECT
     cs.sold_date_sk,
     d.d_year,
     cs.customer_sk,
     cs.channel,
     MAX(cs.item_sk) AS item_sk,
     MAX(cs.promo_sk) AS promo_sk,
     SUM(cs.net_paid) AS total_net_paid,
     COUNT(*) AS transaction_cnt,
     SUM(cs.quantity) AS total_quantity
   FROM combined_sales cs
   JOIN date_dim d ON cs.sold_date_sk = d.d_date_sk
   WHERE d.d_year BETWEEN 2001 AND 2002
   GROUP BY cs.sold_date_sk, d.d_year, cs.customer_sk, cs.channel
)
SELECT
   sub.d_year,
   sub.c_customer_id,
   sub.name_upp_low,
   sub.email_domain,
   sub.rev_zip,
   sub.last_name_nospace,
   sub.first_name_a_replace,
   sub.first_name_prefix,
   sub.last_name_suffix,
   sub.first_name_len,
   sub.last_name_len,
   sub.clean_email,
   sub.composite_field,
   sub.composite_len,
   sub.composite_alnum,
   sub.composite_parts,
   sub.product_name_lower,
   sub.product_name_reverse,
   sub.product_name_underscored,
   sub.item_desc_prefix,
   sub.item_desc_len,
   sub.item_desc_word_count,
   sub.first_number_in_desc,
   sub.promo_name_slug,
   sub.promo_name_alnum,
   sub.promo_name_reverse,
   sub.promo_name_len,
   sub.channel_detail_prefix,
   sub.total_net_paid,
   sub.transaction_cnt,
   sub.total_quantity,
   sub.rn
FROM (
   SELECT
     sa.d_year,
     cs.c_customer_id,
     cs.name_upp_low,
     cs.email_domain,
     cs.rev_zip,
     cs.last_name_nospace,
     cs.first_name_a_replace,
     cs.first_name_prefix,
     cs.last_name_suffix,
     cs.first_name_len,
     cs.last_name_len,
     cs.clean_email,
     cs.composite_field,
     LENGTH(cs.composite_field) AS composite_len,
     REGEXP_REPLACE(cs.composite_field, '[^A-Za-z0-9]', '') AS composite_alnum,
     CARDINALITY(SPLIT(cs.composite_field, '\\|')) AS composite_parts,
     istr.product_name_lower,
     istr.product_name_reverse,
     istr.product_name_underscored,
     istr.item_desc_prefix,
     istr.item_desc_len,
     istr.item_desc_word_count,
     istr.first_number_in_desc,
     ps.promo_name_slug,
     ps.promo_name_alnum,
     ps.promo_name_reverse,
     ps.promo_name_len,
     ps.channel_detail_prefix,
     sa.total_net_paid,
     sa.transaction_cnt,
     sa.total_quantity,
     ROW_NUMBER() OVER (PARTITION BY sa.d_year ORDER BY sa.total_net_paid DESC) AS rn
   FROM sales_agg sa
   JOIN customer_strings cs ON sa.customer_sk = cs.c_customer_sk
   LEFT JOIN item_strings istr ON sa.item_sk = istr.i_item_sk
   LEFT JOIN promo_strings ps ON sa.promo_sk = ps.p_promo_sk
) sub
WHERE sub.rn <= 10
ORDER BY sub.d_year, sub.rn
