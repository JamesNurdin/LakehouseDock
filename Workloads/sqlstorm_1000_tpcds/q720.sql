WITH cust_strings AS (
    SELECT
        c.c_customer_sk,
        lower(c.c_email_address) AS email_lc,
        split(c.c_email_address, '@')[2] AS email_domain,
        length(c.c_email_address) AS email_len,
        length(split(c.c_email_address, '@')[2]) AS domain_len,
        regexp_replace(c.c_email_address, '[^a-z0-9@]', '') AS email_alnum,
        length(regexp_replace(c.c_email_address, '[^a-z0-9@]', '')) AS email_alnum_len,
        lower(c.c_first_name) AS fn_lc,
        upper(c.c_last_name) AS ln_uc,
        concat_ws(' ', c.c_first_name, c.c_last_name) AS full_name,
        length(concat_ws(' ', c.c_first_name, c.c_last_name)) AS full_name_len,
        regexp_extract(c.c_first_name, '^(.*?)(?= )', 1) AS first_part
    FROM customer c
),
addr_strings AS (
    SELECT
        ca.ca_address_sk,
        trim(concat_ws(' ', ca.ca_street_number, ca.ca_street_name, ca.ca_street_type, ca.ca_suite_number, ca.ca_city, ca.ca_state, ca.ca_zip)) AS norm_address,
        length(trim(concat_ws(' ', ca.ca_street_number, ca.ca_street_name, ca.ca_street_type, ca.ca_suite_number, ca.ca_city, ca.ca_state, ca.ca_zip))) AS norm_address_len,
        regexp_replace(ca.ca_street_name, '(?i)[^a-z]', '') AS street_alpha,
        length(regexp_replace(ca.ca_street_name, '(?i)[^a-z]', '')) AS street_alpha_len
    FROM customer_address ca
),
item_strings AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        lower(i.i_product_name) AS product_name_lc,
        length(i.i_product_name) AS product_name_len,
        regexp_replace(i.i_product_name, '[^0-9]', '') AS product_digits,
        length(regexp_replace(i.i_product_name, '[^0-9]', '')) AS product_digits_len,
        regexp_extract(i.i_product_name, '^([^ ]+)', 1) AS product_first_word
    FROM item i
),
url_strings AS (
    SELECT
        wp.wp_web_page_sk,
        lower(regexp_extract(wp.wp_url, 'https?://([^/]+)/?', 1)) AS url_domain,
        length(wp.wp_url) AS url_len,
        replace(wp.wp_url, 'http://', '') AS url_no_http,
        length(replace(wp.wp_url, 'http://', '')) AS url_no_http_len,
        regexp_replace(wp.wp_url, '[^a-zA-Z0-9]', '') AS url_alnum,
        length(regexp_replace(wp.wp_url, '[^a-zA-Z0-9]', '')) AS url_alnum_len
    FROM web_page wp
)
SELECT
    d.d_year,
    count(DISTINCT ss.ss_ticket_number) AS tickets,
    sum(ss.ss_net_paid) AS total_net_paid,
    avg(cs.email_len) AS avg_email_len,
    avg(cs.domain_len) AS avg_email_domain_len,
    avg(a.norm_address_len) AS avg_address_len,
    avg(i.product_name_len) AS avg_product_name_len,
    avg(u.url_len) AS avg_url_len,
    approx_distinct(cs.email_domain) AS distinct_email_domains,
    approx_percentile(ss.ss_net_paid, 0.5) AS median_net_paid,
    slice(array_agg(DISTINCT lower(i.product_first_word) ORDER BY lower(i.product_first_word)), 1, 10) AS top_product_first_words,
    max(u.url_alnum_len) AS max_url_alnum_len
FROM store_sales ss
LEFT JOIN cust_strings cs ON ss.ss_customer_sk = cs.c_customer_sk
LEFT JOIN addr_strings a ON ss.ss_addr_sk = a.ca_address_sk
LEFT JOIN item_strings i ON ss.ss_item_sk = i.i_item_sk
LEFT JOIN url_strings u ON mod(ss.ss_store_sk, 1000) = mod(u.wp_web_page_sk, 1000)
LEFT JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE ss.ss_sold_date_sk IS NOT NULL
GROUP BY d.d_year
ORDER BY d.d_year
