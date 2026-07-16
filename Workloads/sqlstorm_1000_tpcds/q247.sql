WITH
    sales AS (
        SELECT
            ss.*,
            d.d_year,
            i.i_product_name,
            i.i_color,
            i.i_size,
            s.s_store_name,
            s.s_city,
            s.s_state,
            c.c_first_name,
            c.c_last_name,
            c.c_email_address,
            ca.ca_street_number,
            ca.ca_street_name,
            ca.ca_street_type,
            ca.ca_city AS addr_city,
            ca.ca_state AS addr_state,
            ca.ca_zip,
            ca.ca_country
        FROM store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        LEFT JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
        WHERE d.d_year BETWEEN 1999 AND 2000
    )
SELECT
    s.d_year,
    COUNT(*) AS total_sales,
    SUM(s.ss_net_paid) AS total_net_paid,
    COUNT(DISTINCT concat_ws(' ', s.c_first_name, s.c_last_name)) AS distinct_customers,
    SUM(CASE WHEN regexp_like(lower(s.c_email_address), '.*@example\\.com$') THEN 1 ELSE 0 END) AS emails_example_com,
    CONCAT_WS(' | ',
        ARRAY_AGG(DISTINCT
            regexp_replace(
                concat_ws(', ',
                    concat_ws(' ', s.ca_street_number, s.ca_street_name, s.ca_street_type),
                    s.addr_city,
                    s.addr_state,
                    s.ca_zip,
                    s.ca_country
                ),
                '\\s+', ' '
            )
        )
    ) AS distinct_cleaned_addresses,
    SUM(CAST(regexp_extract(s.ca_zip, '(\\d+)', 1) AS INTEGER)) AS sum_zip_numbers,
    COUNT(DISTINCT regexp_extract(s.i_product_name, '([A-Z]{2,})', 1)) AS distinct_caps_words_in_product,
    SUM(CASE WHEN regexp_like(s.i_color, '^\\d+$') THEN 1 ELSE 0 END) AS color_all_digits,
    AVG(CARDINALITY(array_distinct(regexp_split(regexp_replace(s.i_product_name, '[^A-Za-z0-9 ]', ''), '\\s+')))) AS avg_unique_words_in_product,
    CONCAT_WS(' || ',
        ARRAY_AGG(DISTINCT
            concat_ws('_',
                lower(s.s_store_name),
                lower(s.s_city),
                lower(s.s_state)
            )
        )
    ) AS store_signature_list,
    ARRAY_AGG(DISTINCT
        array_join(
            slice(regexp_split(regexp_replace(s.i_product_name, '[^A-Za-z0-9 ]', ''), '\\s+'), 1, 3),
            ' '
        )
    ) AS product_first_three_words,
    AVG(length(concat_ws(' ', s.c_first_name, s.c_last_name, s.c_email_address))) AS avg_customer_string_length,
    MAX(length(s.i_product_name)) AS max_product_name_length,
    MIN(length(s.i_product_name)) AS min_product_name_length
FROM sales s
GROUP BY s.d_year
ORDER BY s.d_year
