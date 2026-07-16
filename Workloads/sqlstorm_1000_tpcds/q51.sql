WITH cust_domains AS (
    SELECT c.c_customer_sk,
           lower(split(c.c_email_address, '@')[2]) AS email_domain
    FROM customer c
    WHERE c.c_email_address IS NOT NULL
),
store_info AS (
    SELECT s.s_store_sk,
           s.s_store_id,
           s.s_store_name,
           regexp_replace(concat_ws(', ', s.s_city, s.s_state, s.s_country), '\\s+', ' ') AS full_location,
           lower(trim(s.s_hours)) AS store_hours_norm,
           upper(s.s_store_name) AS store_name_upper,
           replace(s.s_store_name, ' ', '_') AS store_name_underscored,
           reverse(s.s_store_name) AS store_name_rev,
           length(s.s_store_name) AS store_name_len
    FROM store s
),
product_info AS (
    SELECT i.i_item_sk,
           i.i_item_id,
           i.i_product_name,
           i.i_color,
           i.i_size,
           lower(i.i_brand) AS brand_lc,
           regexp_replace(i.i_product_name, '\\s+', '_') AS product_name_underscored,
           cardinality(split(i.i_product_name, ' ')) AS product_name_word_cnt,
           substr(i.i_product_name, 1, 10) AS product_name_prefix
    FROM item i
),
promo_info AS (
    SELECT p.p_promo_sk,
           lower(p.p_promo_name) AS promo_name_lc,
           regexp_extract(p.p_promo_name, '(\\w+)', 1) AS promo_first_word
    FROM promotion p
),
date_info AS (
    SELECT d.d_date_sk,
           d.d_date_id,
           d.d_day_name,
           substr(d.d_date_id, 1, 4) AS date_year,
           regexp_replace(d.d_day_name, 'Day', '') AS day_name_clean
    FROM date_dim d
)
SELECT si.s_store_id,
       si.s_store_name,
       si.full_location,
       si.store_name_upper,
       si.store_name_underscored,
       si.store_name_rev,
       si.store_name_len,
       di.d_date_id,
       di.d_day_name,
       di.date_year,
       di.day_name_clean,
       array_join(array_agg(DISTINCT pi.i_color), ', ') AS distinct_colors,
       array_join(array_agg(DISTINCT pi.i_product_name), ', ') AS distinct_product_names
FROM store_info si
JOIN date_info di ON 1=1
JOIN product_info pi ON 1=1
GROUP BY si.s_store_id,
         si.s_store_name,
         si.full_location,
         si.store_name_upper,
         si.store_name_underscored,
         si.store_name_rev,
         si.store_name_len,
         di.d_date_id,
         di.d_day_name,
         di.date_year,
         di.day_name_clean
