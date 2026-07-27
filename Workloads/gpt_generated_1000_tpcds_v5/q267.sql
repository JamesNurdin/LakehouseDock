WITH filtered_customers AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        c.c_email_address,
        REGEXP_EXTRACT(c.c_email_address, '([^@]+)@(.+)', 2) AS email_domain
    FROM tpcds.customer c
    WHERE REGEXP_LIKE(c.c_email_address, '^.+@example\\.com$')
       OR REGEXP_LIKE(c.c_email_address, '^.+@.*\\.org$')
),
return_activities AS (
    SELECT
        'return' AS source,
        fc.full_name,
        fc.email_domain,
        r.r_reason_desc AS activity_desc,
        SUM(sr.sr_return_amt) AS total_amount,
        COUNT(*) AS transaction_count
    FROM filtered_customers fc
    JOIN tpcds.store_returns sr
        ON sr.sr_customer_sk = fc.c_customer_sk
    JOIN tpcds.reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN tpcds.customer_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE REGEXP_LIKE(r.r_reason_desc, 'defect')
      AND ca.ca_city LIKE 'New%'
    GROUP BY fc.full_name, fc.email_domain, r.r_reason_desc
),
sale_activities AS (
    SELECT
        'sale' AS source,
        fc.full_name,
        fc.email_domain,
        wp.wp_url AS activity_desc,
        SUM(ws.ws_ext_sales_price) AS total_amount,
        COUNT(*) AS transaction_count
    FROM filtered_customers fc
    JOIN tpcds.web_sales ws
        ON ws.ws_bill_customer_sk = fc.c_customer_sk
    JOIN tpcds.web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN tpcds.customer_address ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE wp.wp_url LIKE '%checkout%'
      AND ca.ca_zip LIKE '9%'
    GROUP BY fc.full_name, fc.email_domain, wp.wp_url
)
SELECT *
FROM (
    SELECT * FROM return_activities
    UNION ALL
    SELECT * FROM sale_activities
) combined
ORDER BY total_amount DESC
LIMIT 100
