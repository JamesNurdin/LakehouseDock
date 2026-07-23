WITH email_filtered_customers AS (
    SELECT
        c.c_customer_sk,
        c.c_email_address,
        regexp_extract(c.c_email_address, '@([^.]*)\\.', 1) AS email_domain
    FROM customer c
    WHERE regexp_like(c.c_email_address, '@example\\.com$')
),
store_sales_enriched AS (
    SELECT
        s.s_store_id,
        concat(s.s_store_name, ' (', s.s_city, ')') AS store_label,
        substr(s.s_store_name, 1, 5) AS store_name_prefix,
        efc.email_domain,
        ss.ss_net_profit,
        ss.ss_quantity
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN email_filtered_customers efc ON ss.ss_customer_sk = efc.c_customer_sk
    WHERE i.i_product_name LIKE 'A%'
      AND regexp_like(i.i_item_desc, '\\d{4}')
)
SELECT
    'Store' AS source_type,
    s_store_id AS source_id,
    store_label,
    store_name_prefix,
    email_domain,
    SUM(ss_net_profit) AS total_net_profit,
    SUM(ss_quantity) AS total_quantity,
    COUNT(*) AS transaction_count
FROM store_sales_enriched
GROUP BY
    s_store_id,
    store_label,
    store_name_prefix,
    email_domain
ORDER BY total_net_profit DESC
LIMIT 100
