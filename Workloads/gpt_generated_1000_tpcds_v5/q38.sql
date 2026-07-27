WITH returns_data AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        hd.hd_buy_potential,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt,
        REGEXP_EXTRACT(c.c_email_address, '@(.+)$') AS email_domain
    FROM catalog_returns cr
    JOIN customer c
      ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
      ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE REGEXP_LIKE(c.c_first_name, '^(A|E)')
      AND c.c_email_address LIKE '%@example.com'
    GROUP BY
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        hd.hd_buy_potential,
        REGEXP_EXTRACT(c.c_email_address, '@(.+)$')
),
sales_data AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        hd.hd_buy_potential,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(*) AS sales_cnt,
        REGEXP_EXTRACT(c.c_email_address, '@(.+)$') AS email_domain
    FROM web_sales ws
    JOIN customer c
      ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
      ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE REGEXP_LIKE(c.c_last_name, 'son$')
      AND c.c_email_address LIKE '%@%mail.com'
    GROUP BY
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        hd.hd_buy_potential,
        REGEXP_EXTRACT(c.c_email_address, '@(.+)$')
)
SELECT DISTINCT
    customer_sk,
    first_name,
    last_name,
    buy_potential,
    email_domain,
    metric_type,
    metric_value,
    transaction_cnt
FROM (
    SELECT
        c_customer_sk AS customer_sk,
        c_first_name AS first_name,
        c_last_name AS last_name,
        hd_buy_potential AS buy_potential,
        email_domain,
        'return' AS metric_type,
        total_return_amount AS metric_value,
        return_cnt AS transaction_cnt
    FROM returns_data
    UNION ALL
    SELECT
        c_customer_sk AS customer_sk,
        c_first_name AS first_name,
        c_last_name AS last_name,
        hd_buy_potential AS buy_potential,
        email_domain,
        'sale' AS metric_type,
        total_sales AS metric_value,
        sales_cnt AS transaction_cnt
    FROM sales_data
) combined
ORDER BY metric_value DESC
LIMIT 100
