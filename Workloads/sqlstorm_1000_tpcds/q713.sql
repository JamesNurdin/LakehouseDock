WITH
customer_info AS (
    SELECT
        c_customer_sk,
        concat(c_first_name, ' ', c_last_name) AS full_name,
        lower(c_email_address) AS email_lower,
        regexp_extract(c_email_address, '@(.+)$', 1) AS email_domain,
        regexp_extract(c_customer_id, '([0-9]+)', 1) AS cust_id_numeric,
        length(c_first_name) + length(c_last_name) AS name_length,
        replace(c_salutation, '.', '') AS salutation_clean,
        concat('CUST-', lpad(regexp_extract(c_customer_id, '([0-9]+)', 1), 8, '0')) AS formatted_cust_id
    FROM customer
),
product_info AS (
    SELECT
        i_item_sk,
        i_product_name,
        lower(i_item_desc) AS desc_lower,
        regexp_replace(i_item_desc, '[^a-zA-Z0-9 ]', '') AS desc_alnum,
        substr(i_item_desc, 1, 30) AS desc_prefix,
        length(i_item_desc) AS desc_len,
        concat(i_color, '-', i_size) AS color_size_key,
        coalesce(i_color, 'UNKNOWN') AS color_coalesce,
        replace(i_units, ' ', '_') AS units_underscored
    FROM item
),
store_info AS (
    SELECT
        s_store_sk,
        concat(s_store_name, ' (', s_city, ', ', s_state, ')') AS store_full_name,
        replace(s_hours, ' ', '') AS hours_compact,
        lower(s_market_desc) AS market_desc_lower,
        regexp_replace(s_market_desc, '[^a-z]', '') AS market_desc_alnum,
        length(s_store_name) AS store_name_len
    FROM store
),
sales_data AS (
    SELECT
        ss.ss_customer_sk,
        ss.ss_item_sk,
        ss.ss_store_sk,
        ss.ss_sold_date_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        concat('ORDER-', CAST(ss.ss_ticket_number AS varchar)) AS order_key,
        format('%s-%s-%s', ss.ss_sold_date_sk, ss.ss_item_sk, ss.ss_quantity) AS composite_key,
        CASE WHEN ss.ss_net_paid > 0 THEN 'PROFITABLE' ELSE 'LOSS' END AS profit_status,
        replace(CAST(ss.ss_net_paid AS varchar), '.', ',') AS net_paid_str,
        CAST(ss.ss_net_paid AS varchar) AS net_paid_varchar
    FROM store_sales ss
),
joined AS (
    SELECT
        ci.cust_id_numeric,
        ci.full_name,
        ci.email_domain,
        pi.i_product_name,
        pi.desc_prefix,
        pi.desc_alnum,
        si.store_full_name,
        sd.order_key,
        sd.profit_status,
        sd.net_paid_str,
        format('Customer %s bought %s at %s', ci.full_name, pi.i_product_name, si.store_full_name) AS description
    FROM customer_info ci
    JOIN sales_data sd ON ci.c_customer_sk = sd.ss_customer_sk
    JOIN product_info pi ON sd.ss_item_sk = pi.i_item_sk
    JOIN store_info si ON sd.ss_store_sk = si.s_store_sk
    WHERE regexp_like(ci.email_domain, '^.*\\.com$')
      AND pi.desc_len > 20
      AND si.store_name_len > 5
)
SELECT
    profit_status,
    count(*) AS num_transactions,
    sum(CAST(replace(net_paid_str, ',', '.') AS double)) AS total_net_paid,
    approx_distinct(cust_id_numeric) AS unique_customers,
    max(description) AS example_description,
    array_agg(DISTINCT email_domain) AS email_domains
FROM joined
GROUP BY profit_status
ORDER BY profit_status
