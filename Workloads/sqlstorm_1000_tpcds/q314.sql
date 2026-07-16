WITH
    processed_items AS (
        SELECT
            i_item_sk,
            i_product_name,
            lower(regexp_replace(i_product_name, '[^a-z0-9]', '')) AS norm_name,
            length(i_product_name) AS name_len,
            reverse(i_product_name) AS rev_name,
            lower(i_product_name) = reverse(lower(i_product_name)) AS is_palindrome,
            regexp_extract(i_item_id, '(\\d+)', 1) AS numeric_id,
            concat_ws('-', i_brand, i_class, i_category, i_color) AS composite_tag,
            cardinality(split(i_product_name, '\\s+')) AS token_count
        FROM item
    ),
    address_processed AS (
        SELECT
            ca_address_sk,
            concat_ws(' ', ca_street_number, ca_street_name, ca_street_type, ca_suite_number) AS full_address,
            lower(regexp_replace(concat_ws(' ', ca_street_number, ca_street_name, ca_street_type, ca_suite_number), '[^a-z0-9]', '')) AS norm_address,
            length(concat_ws(' ', ca_street_number, ca_street_name, ca_street_type, ca_suite_number)) AS address_len,
            cardinality(split(concat_ws(' ', ca_street_number, ca_street_name, ca_street_type, ca_suite_number), '\\s+')) AS address_token_count,
            ca_city,
            ca_state
        FROM customer_address
    ),
    sales_union AS (
        SELECT
            cs.cs_sold_date_sk AS date_sk,
            cs.cs_item_sk AS item_sk,
            cs.cs_quantity AS quantity,
            cs.cs_net_paid AS net_paid,
            cs.cs_ship_addr_sk AS addr_sk,
            'catalog' AS channel
        FROM catalog_sales cs
        UNION ALL
        SELECT
            ss.ss_sold_date_sk,
            ss.ss_item_sk,
            ss.ss_quantity,
            ss.ss_net_paid,
            ss.ss_addr_sk,
            'store'
        FROM store_sales ss
        UNION ALL
        SELECT
            ws.ws_sold_date_sk,
            ws.ws_item_sk,
            ws.ws_quantity,
            ws.ws_net_paid,
            ws.ws_ship_addr_sk,
            'web'
        FROM web_sales ws
    ),
    joined_data AS (
        SELECT
            su.channel,
            d.d_year,
            d.d_month_seq,
            p.norm_name,
            p.name_len,
            p.is_palindrome,
            p.numeric_id,
            p.composite_tag,
            p.token_count,
            a.norm_address,
            a.address_len,
            a.address_token_count,
            a.ca_city,
            a.ca_state,
            su.quantity,
            su.net_paid
        FROM sales_union su
        JOIN date_dim d ON su.date_sk = d.d_date_sk
        JOIN processed_items p ON su.item_sk = p.i_item_sk
        JOIN address_processed a ON su.addr_sk = a.ca_address_sk
    )
SELECT
    channel,
    d_year,
    d_month_seq,
    COUNT(DISTINCT norm_name) AS distinct_norm_names,
    COUNT(DISTINCT norm_address) AS distinct_norm_addresses,
    SUM(quantity) AS sum_quantity,
    SUM(net_paid) AS sum_net_paid,
    SUM(CASE WHEN is_palindrome THEN quantity ELSE 0 END) AS palindrome_quantity,
    SUM(CASE WHEN regexp_like(norm_address, '^new') THEN quantity ELSE 0 END) AS new_city_quantity,
    approx_percentile(net_paid, 0.5) AS median_net_paid,
    MAX(name_len) AS max_name_len,
    MIN(name_len) AS min_name_len,
    AVG(token_count) AS avg_product_token_count,
    AVG(address_token_count) AS avg_address_token_count,
    AVG(address_len) AS avg_address_len,
    COUNT(*) AS transaction_count
FROM joined_data
GROUP BY
    channel,
    d_year,
    d_month_seq
ORDER BY
    channel,
    d_year DESC,
    d_month_seq
