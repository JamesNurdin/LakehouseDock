WITH sales_data AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_city,
        s.s_state,
        s.s_manager,
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        i.i_item_sk,
        i.i_product_name,
        i.i_item_desc,
        ss.ss_quantity,
        ss.ss_sales_price,
        ss.ss_ext_sales_price,
        d.d_date,
        d.d_day_name
    FROM store s
    JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE ss.ss_sold_date_sk IS NOT NULL
),
processed AS (
    SELECT
        s_store_sk,
        s_store_name,
        s_city,
        s_state,
        s_manager,
        c_customer_sk,
        concat(upper(s_store_name), ' - ', lower(s_city), ', ', s_state) AS store_location_normalized,
        concat(c_first_name, ' ', c_last_name) AS customer_full_name,
        regexp_extract(c_email_address, '@([^@]+)$', 1) AS email_domain,
        lower(regexp_replace(i_product_name, '[^a-zA-Z0-9]+', '_')) AS product_name_clean,
        translate(lower(regexp_replace(i_product_name, '[^a-zA-Z0-9]+', '_')), 'aeiou', '') AS product_name_no_vowels,
        substr(i_item_desc, 1, 30) AS product_desc_snippet,
        length(c_email_address) AS email_len,
        length(concat(s_store_name, s_city, s_state)) AS store_full_len,
        CASE
            WHEN ss_quantity >= 10 THEN 'bulk'
            WHEN ss_quantity >= 5 THEN 'medium'
            ELSE 'single'
        END AS quantity_category,
        repeat('#', (length(lower(regexp_replace(i_product_name, '[^a-zA-Z0-9]+', '_'))) % 10) + 1) AS length_hash,
        format('%.2f', ss_sales_price) AS sales_price_formatted,
        concat('Price:', format('%.2f', ss_sales_price), ' USD') AS formatted_price,
        concat('Date:', CAST(d_date AS varchar), ' (', d_day_name, ')') AS date_formatted,
        array_join(array[
            concat('Store:', s_store_name),
            concat('Customer:', c_first_name, ' ', c_last_name),
            concat('Product:', lower(regexp_replace(i_product_name, '[^a-zA-Z0-9]+', '_'))),
            concat('Qty:', CAST(ss_quantity AS varchar)),
            concat('Total:', CAST(ss_ext_sales_price AS varchar))
        ], ' | ') AS summary_line,
        ss_quantity,
        ss_ext_sales_price
    FROM sales_data
),
aggregated AS (
    SELECT
        s_store_sk,
        s_store_name,
        s_city,
        s_state,
        count(*) AS total_transactions,
        sum(ss_quantity) AS total_quantity,
        sum(ss_ext_sales_price) AS total_sales,
        avg(email_len) AS avg_email_len,
        avg(length(product_name_clean)) AS avg_product_name_len,
        array_join(array_distinct(array_agg(email_domain) FILTER (WHERE email_domain IS NOT NULL)), ', ') AS distinct_email_domains,
        array_join(array_distinct(array_agg(quantity_category) FILTER (WHERE quantity_category IS NOT NULL)), ', ') AS quantity_categories,
        max(length(summary_line)) AS max_summary_len,
        min(length(summary_line)) AS min_summary_len,
        avg(length(summary_line)) AS avg_summary_len,
        array_join(array_distinct(array_agg(product_name_clean) FILTER (WHERE product_name_clean IS NOT NULL)), '||') AS all_products_concat
    FROM processed
    GROUP BY s_store_sk, s_store_name, s_city, s_state
)
SELECT
    s_store_sk,
    s_store_name,
    s_city,
    s_state,
    total_transactions,
    total_quantity,
    total_sales,
    round(avg_email_len, 2) AS avg_email_len,
    round(avg_product_name_len, 2) AS avg_product_name_len,
    distinct_email_domains,
    quantity_categories,
    max_summary_len,
    min_summary_len,
    round(avg_summary_len, 2) AS avg_summary_len,
    all_products_concat
FROM aggregated
ORDER BY total_sales DESC
LIMIT 100
