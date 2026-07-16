WITH sales_union AS (
    SELECT
        cs_bill_customer_sk AS cust_sk,
        cs_net_paid AS net_paid,
        cs_order_number AS order_number,
        cs_quantity AS quantity,
        cs_sales_price,
        cs_ext_sales_price,
        CAST('catalog' AS varchar) AS sales_channel,
        cs_sold_date_sk AS date_sk
    FROM catalog_sales
    UNION ALL
    SELECT
        ss_customer_sk AS cust_sk,
        ss_net_paid AS net_paid,
        ss_ticket_number AS order_number,
        ss_quantity AS quantity,
        ss_sales_price,
        ss_ext_sales_price,
        CAST('store' AS varchar) AS sales_channel,
        ss_sold_date_sk AS date_sk
    FROM store_sales
    UNION ALL
    SELECT
        ws_bill_customer_sk AS cust_sk,
        ws_net_paid AS net_paid,
        ws_order_number AS order_number,
        ws_quantity AS quantity,
        ws_sales_price,
        ws_ext_sales_price,
        CAST('web' AS varchar) AS sales_channel,
        ws_sold_date_sk AS date_sk
    FROM web_sales
),
customer_strings AS (
    SELECT
        c.c_customer_sk,
        lower(c.c_first_name) || ' ' || lower(c.c_last_name) AS lower_full_name,
        upper(c.c_first_name) || '_' || upper(c.c_last_name) AS upper_full_name_underscore,
        regexp_extract(c.c_email_address, '@(.+)$', 1) AS email_domain,
        replace(c.c_login, '-', '_') AS login_underscored,
        substr(c.c_salutation, 1, 1) || '.' || substr(c.c_first_name, 1, 1) || '.' || substr(c.c_last_name, 1, 1) AS initials,
        length(c.c_email_address) AS email_length,
        regexp_replace(c.c_email_address, '[^@]+', 'x') AS masked_email,
        concat_ws(' ', c.c_salutation, c.c_first_name, c.c_last_name) AS formal_name,
        trim(both ' ' FROM c.c_first_name || ' ' || c.c_last_name) AS trimmed_name,
        ca.ca_city || ', ' || ca.ca_state || ' ' || ca.ca_zip AS address_str
    FROM customer c
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_aggregated AS (
    SELECT
        su.cust_sk,
        SUM(su.net_paid) AS total_net_paid,
        COUNT(*) AS txn_count,
        MIN(su.net_paid) AS min_net,
        MAX(su.net_paid) AS max_net,
        AVG(su.net_paid) AS avg_net,
        approx_percentile(su.net_paid, 0.5) AS median_net,
        SUM(su.quantity) AS total_quantity
    FROM sales_union su
    GROUP BY su.cust_sk
)
SELECT
    cs.c_customer_sk,
    cs.lower_full_name,
    cs.upper_full_name_underscore,
    cs.email_domain,
    cs.login_underscored,
    cs.initials,
    cs.email_length,
    cs.masked_email,
    cs.formal_name,
    cs.trimmed_name,
    cs.address_str,
    sa.total_net_paid,
    sa.txn_count,
    sa.min_net,
    sa.max_net,
    sa.avg_net,
    sa.median_net,
    sa.total_quantity,
    CONCAT(cs.lower_full_name, '@', COALESCE(cs.email_domain, 'unknown.com')) AS synthetic_email,
    REPEAT('x', GREATEST(0, 10 - cs.email_length)) || cs.email_domain AS padded_email_domain,
    regexp_replace(cs.formal_name, '\\s+', '-') AS hyphenated_formal_name,
    LENGTH(cs.upper_full_name_underscore) - LENGTH(REPLACE(cs.upper_full_name_underscore, '_', '')) AS underscore_count,
    CASE
        WHEN sa.total_net_paid > 100000 THEN 'VIP'
        WHEN sa.total_net_paid > 50000 THEN 'Gold'
        WHEN sa.total_net_paid > 10000 THEN 'Silver'
        ELSE 'Bronze'
    END AS customer_tier
FROM customer_strings cs
LEFT JOIN sales_aggregated sa ON cs.c_customer_sk = sa.cust_sk
ORDER BY sa.total_net_paid DESC NULLS LAST
LIMIT 100
