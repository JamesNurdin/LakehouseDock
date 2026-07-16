WITH 
sales_src AS (
    SELECT 'store' AS channel,
           ss.ss_sold_date_sk AS sold_date_sk,
           ss.ss_item_sk AS item_sk,
           ss.ss_store_sk AS location_sk,
           ss.ss_customer_sk AS customer_sk,
           ss.ss_net_paid AS net_paid,
           ss.ss_ticket_number AS ticket_number
    FROM store_sales ss
    UNION ALL
    SELECT 'catalog' AS channel,
           cs.cs_sold_date_sk,
           cs.cs_item_sk,
           cs.cs_call_center_sk,
           cs.cs_bill_customer_sk,
           cs.cs_net_paid,
           cs.cs_order_number
    FROM catalog_sales cs
    UNION ALL
    SELECT 'web' AS channel,
           ws.ws_sold_date_sk,
           ws.ws_item_sk,
           ws.ws_web_page_sk,
           ws.ws_bill_customer_sk,
           ws.ws_net_paid,
           ws.ws_order_number
    FROM web_sales ws
),
item_desc AS (
    SELECT i.i_item_sk,
           i.i_product_name,
           i.i_color,
           i.i_size,
           i.i_brand,
           i.i_category,
           i.i_manufact,
           i.i_units
    FROM item i
),
cust_desc AS (
    SELECT c.c_customer_sk,
           concat_ws(' ', c.c_first_name, c.c_last_name) AS full_name,
           lower(concat_ws(' ', c.c_first_name, c.c_last_name)) AS lower_name,
           length(concat_ws(' ', c.c_first_name, c.c_last_name)) AS name_len
    FROM customer c
),
joined AS (
    SELECT s.channel,
           d.d_year,
           d.d_month_seq,
           i.i_product_name,
           i.i_color,
           i.i_size,
           i.i_brand,
           i.i_category,
           i.i_manufact,
           i.i_units,
           coalesce(c.full_name, 'UNKNOWN') AS customer_name,
           s.net_paid,
           concat_ws(' | ', i.i_product_name, i.i_color, i.i_size, i.i_brand, i.i_category, i.i_manufact, c.full_name) AS raw_desc,
           lower(concat_ws(' ', i.i_product_name, i.i_color, i.i_size, i.i_brand, i.i_category, i.i_manufact, c.full_name)) AS lower_desc,
           regexp_replace(concat_ws(' ', i.i_product_name, i.i_color, i.i_size, i.i_brand, i.i_category, i.i_manufact, c.full_name), '[^A-Za-z0-9 ]', '') AS cleaned_desc,
           length(regexp_replace(concat_ws(' ', i.i_product_name, i.i_color, i.i_size, i.i_brand, i.i_category, i.i_manufact, c.full_name), '[^A-Za-z0-9 ]', '')) AS cleaned_len,
           cardinality(regexp_extract_all(lower(concat_ws(' ', i.i_product_name, i.i_color, i.i_size, i.i_brand, i.i_category, i.i_manufact, c.full_name)), '[aeiou]')) AS vowel_cnt,
           cardinality(regexp_extract_all(lower(concat_ws(' ', i.i_product_name, i.i_color, i.i_size, i.i_brand, i.i_category, i.i_manufact, c.full_name)), '[^aeiou]')) AS consonant_cnt,
           substring(i.i_product_name, 1, 10) AS short_product_name,
           replace(i.i_category, ' ', '_') AS cat_underscore,
           concat_ws('_', i.i_brand, i.i_category, i.i_manufact) AS compound_key
    FROM sales_src s
    JOIN date_dim d ON s.sold_date_sk = d.d_date_sk
    JOIN item_desc i ON s.item_sk = i.i_item_sk
    LEFT JOIN cust_desc c ON s.customer_sk = c.c_customer_sk
)
SELECT channel,
       d_year,
       d_month_seq,
       count(*) AS sales_cnt,
       sum(net_paid) AS total_net_paid,
       avg(cleaned_len) AS avg_desc_len,
       avg(vowel_cnt) AS avg_vowel_cnt,
       avg(consonant_cnt) AS avg_consonant_cnt,
       approx_percentile(vowel_cnt, 0.5) AS median_vowel_cnt,
       approx_percentile(cleaned_len, 0.9) AS p90_desc_len,
       max(compound_key) AS max_compound_key,
       min(short_product_name) AS min_product_prefix
FROM joined
GROUP BY channel, d_year, d_month_seq
ORDER BY total_net_paid DESC
LIMIT 100
