WITH
customer_info AS (
    SELECT
        c_customer_sk,
        c_current_addr_sk,
        concat_ws(' ', trim(c_first_name), trim(c_last_name)) AS full_name,
        lower(trim(c_email_address)) AS email_lower,
        CASE WHEN regexp_like(c_email_address, '^.+@.+\\..+$') THEN 1 ELSE 0 END AS email_valid,
        length(trim(c_first_name)) + length(trim(c_last_name)) AS name_len
    FROM customer
),
address_info AS (
    SELECT
        ca_address_sk,
        concat_ws(', ',
            concat_ws(' ', ca_street_number, ca_street_name, ca_street_type),
            ca_city,
            ca_state,
            ca_zip) AS full_address,
        length(concat_ws(' ', ca_street_number, ca_street_name, ca_street_type, ca_city, ca_state, ca_zip)) AS address_len,
        regexp_replace(ca_city, '[AEIOUaeiou]', '') AS city_no_vowels
    FROM customer_address
),
item_info AS (
    SELECT
        i_item_sk,
        i_product_name,
        regexp_replace(i_item_desc, '[^A-Za-z0-9 ]', '') AS cleaned_desc,
        lower(i_color) AS color_lower,
        upper(i_size) AS size_upper,
        replace(i_units, ' ', '') AS units_nospace,
        concat_ws('|', i_brand, i_class, i_category) AS hierarchy,
        length(i_item_desc) AS desc_len,
        substr(i_item_desc, 1, 20) AS desc_prefix
    FROM item
),
promo_info AS (
    SELECT
        p_promo_sk,
        p_promo_name,
        lower(p_promo_name) AS promo_name_lower,
        regexp_replace(p_promo_name, '\\s+', '_') AS promo_name_underscore,
        length(p_promo_name) AS promo_name_len
    FROM promotion
),
order_strings AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        concat_ws('||',
            concat('ORD', lpad(CAST(ws.ws_order_number AS varchar), 12, '0')),
            ci.full_name,
            ai.full_address,
            ii.cleaned_desc,
            pi.promo_name_underscore) AS raw_concat,
        length(concat_ws('||',
            concat('ORD', lpad(CAST(ws.ws_order_number AS varchar), 12, '0')),
            ci.full_name,
            ai.full_address,
            ii.cleaned_desc,
            pi.promo_name_underscore)) AS raw_concat_len,
        regexp_like(concat_ws('||',
            concat('ORD', lpad(CAST(ws.ws_order_number AS varchar), 12, '0')),
            ci.full_name,
            ai.full_address,
            ii.cleaned_desc,
            pi.promo_name_underscore), '\\d{5}') AS contains_five_digits
    FROM web_sales ws
    JOIN customer_info ci ON ws.ws_bill_customer_sk = ci.c_customer_sk
    JOIN address_info ai ON ci.c_current_addr_sk = ai.ca_address_sk
    JOIN item_info ii ON ws.ws_item_sk = ii.i_item_sk
    JOIN promo_info pi ON ws.ws_promo_sk = pi.p_promo_sk
)
SELECT
    d.d_date,
    count(*) AS order_count,
    sum(os.raw_concat_len) AS total_concat_len,
    avg(os.raw_concat_len) AS avg_concat_len,
    approx_percentile(os.raw_concat_len, 0.5) AS median_concat_len,
    sum(CASE WHEN os.contains_five_digits THEN 1 ELSE 0 END) AS orders_with_five_digits,
    max(os.raw_concat_len) AS max_concat_len,
    min(os.raw_concat_len) AS min_concat_len
FROM order_strings os
JOIN date_dim d ON os.ws_sold_date_sk = d.d_date_sk
GROUP BY d.d_date
ORDER BY d.d_date
LIMIT 100
