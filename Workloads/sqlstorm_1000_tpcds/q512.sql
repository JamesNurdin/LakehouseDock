WITH
customer_email AS (
    SELECT
        c_customer_sk,
        lower(c_email_address) AS email_lower,
        regexp_extract(c_email_address, '@([^.]*)') AS email_domain,
        concat_ws(' ', c_salutation, c_first_name, c_last_name) AS full_name,
        length(c_email_address) AS email_len
    FROM
        customer
    WHERE
        regexp_like(c_email_address, '@[A-Za-z0-9.-]+\\.com$')
),
address_clean AS (
    SELECT
        ca_address_sk,
        trim(both ' ' FROM concat_ws(', ',
            ca_street_number,
            ca_street_name,
            ca_street_type,
            CASE
                WHEN ca_suite_number IS NOT NULL AND ca_suite_number <> '' THEN concat('Suite ', ca_suite_number)
                ELSE NULL
            END,
            ca_city,
            ca_state,
            ca_zip,
            ca_country
        )) AS full_address
    FROM
        customer_address
),
product_strings AS (
    SELECT
        i_item_sk,
        i_product_name,
        i_item_desc,
        regexp_replace(i_item_desc, '\\s+', '_') AS desc_underscored,
        regexp_extract(i_item_desc, '^([^ ]+)') AS first_word_desc,
        length(i_item_desc) AS desc_len,
        lower(i_product_name) AS product_name_lower
    FROM
        item
),
sales_with_strings AS (
    SELECT
        ss.ss_sold_date_sk,
        d.d_date,
        ss.ss_customer_sk,
        ss.ss_item_sk,
        ss.ss_net_profit,
        ce.full_name,
        ce.email_domain,
        ad.full_address,
        ps.first_word_desc,
        ps.desc_underscored,
        ps.product_name_lower,
        regexp_replace(ce.full_name, '[^A-Za-z]', '') AS clean_name,
        length(ce.full_name) AS name_len,
        strpos(ps.first_word_desc, 'e') AS pos_e_in_desc,
        CASE
            WHEN regexp_like(ps.first_word_desc, '^A.*') THEN 'StartsWithA'
            WHEN regexp_like(ps.first_word_desc, '.*e$') THEN 'EndsWithE'
            ELSE 'Other'
        END AS desc_category
    FROM
        store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN customer_email ce ON ss.ss_customer_sk = ce.c_customer_sk
        JOIN address_clean ad ON ss.ss_addr_sk = ad.ca_address_sk
        JOIN product_strings ps ON ss.ss_item_sk = ps.i_item_sk
    WHERE
        ss.ss_quantity > 0
        AND ps.desc_len > 10
)
SELECT
    d_date,
    desc_category,
    email_domain,
    count(*) AS sales_cnt,
    sum(ss_net_profit) AS total_profit,
    avg(name_len) AS avg_name_len,
    avg(length(clean_name)) AS avg_clean_name_len,
    approx_distinct(full_name) AS approx_unique_customers,
    max(desc_underscored) FILTER (WHERE strpos(desc_underscored, 'e') > 0) AS sample_desc_with_e,
    slice(array_sort(array_agg(distinct product_name_lower)), 1, 5) AS top5_products
FROM
    sales_with_strings
GROUP BY
    d_date,
    desc_category,
    email_domain
ORDER BY
    total_profit DESC
LIMIT 100
