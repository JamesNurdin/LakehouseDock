WITH 
customer_email_domains AS (
    SELECT 
        c_customer_sk,
        lower(c_email_address) AS email_lower,
        regexp_extract(lower(c_email_address), '@([^\\.]+\\.[^\\.]+)', 1) AS email_domain,
        regexp_extract(lower(c_email_address), '^([^@]+)', 1) AS email_user
    FROM customer
),
call_center_augmented AS (
    SELECT 
        cc_call_center_sk,
        cc_manager,
        concat_ws(' - ', cc_name, cc_manager) AS cc_full_desc,
        translate(cc_manager, 'aeiou', 'AEIOU') AS manager_vowel_upper,
        length(cc_name) AS name_len,
        lower(cc_city) AS city_lower,
        upper(cc_state) AS state_upper,
        regexp_replace(cc_hours, '[^0-9]', '') AS hours_digits
    FROM call_center
),
item_augmented AS (
    SELECT 
        i_item_sk,
        i_item_id,
        i_product_name,
        i_brand,
        i_color,
        concat_ws(' ', i_brand, i_item_id, i_color) AS item_desc,
        substr(i_product_name, 1, 10) AS prod_name_prefix,
        lower(i_product_name) AS prod_name_lower,
        length(i_product_name) AS prod_name_len,
        regexp_replace(i_product_name, '[^A-Za-z0-9]', '') AS prod_name_alnum
    FROM item
),
sales_strings AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_quantity,
        ws.ws_sales_price AS sales_price,
        ws.ws_net_paid AS net_paid,
        c.c_customer_sk,
        i.i_item_sk,
        i.item_desc,
        substr(i.item_desc, 1, 5) AS item_desc_prefix,
        replace(i.item_desc, ' ', '_') AS item_desc_underscored,
        array_join(split(i.item_desc, ' '), '|') AS item_desc_pipe,
        length(i.item_desc) AS item_desc_len,
        lower(i.item_desc) AS item_desc_lower,
        upper(i.item_desc) AS item_desc_upper,
        regexp_extract(i.item_desc, '(\\w+)', 1) AS first_word,
        ce.email_domain,
        cca.cc_full_desc,
        cca.manager_vowel_upper,
        concat_ws(' :: ', cca.cc_full_desc, i.item_desc) AS combined_desc,
        date_dim.d_year,
        date_dim.d_month_seq,
        CAST(date_dim.d_date AS VARCHAR) AS date_str,
        substr(CAST(date_dim.d_date AS VARCHAR), 1, 10) AS date_str_prefix,
        replace(CAST(date_dim.d_date AS VARCHAR), '-', '/') AS date_slash,
        length(CAST(date_dim.d_date AS VARCHAR)) AS date_str_len,
        lower(CAST(date_dim.d_date AS VARCHAR)) AS date_str_lower
    FROM web_sales ws
    JOIN date_dim ON ws.ws_sold_date_sk = date_dim.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN customer_email_domains ce ON c.c_customer_sk = ce.c_customer_sk
    JOIN item_augmented i ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN call_center_augmented cca 
        ON (mod(ws.ws_order_number, 500) + 1) = cca.cc_call_center_sk
)

SELECT
    d_year,
    d_month_seq,
    count(*) AS total_orders,
    sum(sales_price) AS total_sales,
    sum(net_paid) AS total_net_paid,
    avg(item_desc_len) AS avg_item_desc_len,
    max(item_desc_upper) AS max_item_desc_upper,
    min(email_domain) AS min_email_domain,
    count(DISTINCT email_domain) AS distinct_email_domains,
    array_agg(DISTINCT item_desc_pipe) AS distinct_item_desc_pipes,
    concat_ws(' | ',
        concat('Year:', CAST(d_year AS VARCHAR)),
        concat('Month:', CAST((d_month_seq % 12 + 1) AS VARCHAR)),
        concat('Orders:', CAST(count(*) AS VARCHAR)),
        concat('UniqueDomains:', CAST(count(DISTINCT email_domain) AS VARCHAR))
    ) AS benchmark_summary
FROM sales_strings
GROUP BY d_year, d_month_seq
ORDER BY d_year, d_month_seq
LIMIT 100
