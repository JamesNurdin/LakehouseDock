WITH sales_data AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_item_sk,
        cs.cs_promo_sk,
        split_part(i.i_product_name, ' ', 1) AS product_first_word,
        lower(i.i_product_name) AS product_name_lc,
        length(i.i_product_name) AS product_name_len,
        reverse(i.i_product_name) AS product_name_rev,
        regexp_extract(i.i_item_desc, '(\\w+)', 1) AS first_word_desc,
        length(regexp_replace(i.i_item_desc, '[^a-zA-Z]', '')) AS alpha_len_item_desc,
        substring(i.i_item_desc, 1, 10) AS item_desc_prefix,
        concat_ws(' ', i.i_brand, i.i_class, i.i_category) AS brand_class_category,
        lower(trim(i.i_color)) AS color_trimmed,
        translate(i.i_size, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz') AS size_lower,
        concat(c.c_first_name, ' ', c.c_last_name) AS customer_full_name,
        regexp_extract(c.c_email_address, '@(.+)$', 1) AS email_domain,
        length(c.c_email_address) AS email_len,
        lower(replace(c.c_email_address, '.', '')) AS email_normalized,
        cc.cc_name AS call_center_name,
        lower(cc.cc_hours) AS cc_hours_normalized,
        cp.cp_description AS catalog_desc,
        regexp_replace(cp.cp_description, '\\s+', ' ') AS catalog_desc_clean,
        length(cp.cp_description) AS catalog_desc_len,
        concat_ws('-', cp.cp_department, cp.cp_type) AS catalog_dept_type,
        wp.wp_url,
        regexp_extract(wp.wp_url, 'https?://([^/]+)', 1) AS url_host,
        length(wp.wp_url) AS url_len,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_ext_sales_price AS ws_sales_price,
        CAST(ws.ws_ship_mode_sk AS varchar) AS ship_mode_str,
        TIMESTAMP '2024-10-01 00:00:00' AS benchmark_timestamp
    FROM
        catalog_sales cs
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
        LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        LEFT JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        LEFT JOIN web_sales ws ON ws.ws_order_number = cs.cs_order_number
        LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE
        cs.cs_sold_date_sk BETWEEN 2450815 AND 2451179
),
aggregated AS (
    SELECT
        call_center_name,
        lower(call_center_name) AS call_center_name_lc,
        concat_ws(' | ', call_center_name, catalog_dept_type) AS call_center_catalog_key,
        regexp_replace(call_center_name, '[^A-Za-z]', '') AS call_center_alpha,
        length(call_center_name) AS call_center_name_len,
        sum(cs_ext_sales_price) AS total_sales,
        avg(product_name_len) AS avg_product_name_len,
        sum(alpha_len_item_desc) AS total_alpha_desc_len,
        count(DISTINCT email_domain) AS distinct_email_domains,
        approx_distinct(customer_full_name) AS approx_distinct_customers,
        count(*) AS transaction_count,
        max(benchmark_timestamp) AS latest_timestamp
    FROM
        sales_data
    GROUP BY
        call_center_name,
        lower(call_center_name),
        concat_ws(' | ', call_center_name, catalog_dept_type),
        regexp_replace(call_center_name, '[^A-Za-z]', ''),
        length(call_center_name)
)
SELECT
    call_center_name,
    call_center_name_lc,
    call_center_alpha,
    call_center_name_len,
    total_sales,
    avg_product_name_len,
    total_alpha_desc_len,
    distinct_email_domains,
    approx_distinct_customers,
    transaction_count,
    latest_timestamp
FROM
    aggregated
ORDER BY
    total_sales DESC
LIMIT 20
