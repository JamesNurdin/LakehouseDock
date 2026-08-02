WITH sampled_customers AS (
    SELECT *
    FROM tpcds.customer
    TABLESAMPLE BERNOULLI (10)
),
web_sales_agg AS (
    SELECT
        c.c_customer_id AS customer_id,
        concat(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        'Web Sales' AS source,
        SUM(ws.ws_net_paid) AS total_amount,
        CASE WHEN SUM(ws.ws_net_paid) > 1000 THEN 'High' ELSE 'Low' END AS amount_category,
        REGEXP_EXTRACT(c.c_email_address, '@(.+)$') AS email_domain
    FROM sampled_customers AS c
    JOIN tpcds.web_sales AS ws
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE
        REGEXP_LIKE(c.c_email_address, '^.+@.+\\.com$')
        AND c.c_first_name LIKE 'M%'
    GROUP BY
        c.c_customer_id,
        concat(c.c_first_name, ' ', c.c_last_name),
        c.c_email_address
),
store_returns_agg AS (
    SELECT
        c.c_customer_id AS customer_id,
        concat(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        'Store Returns' AS source,
        SUM(sr.sr_net_loss) AS total_amount,
        CASE WHEN SUM(sr.sr_net_loss) > 0 THEN 'Loss' ELSE 'Gain' END AS amount_category,
        REGEXP_EXTRACT(c.c_email_address, '@(.+)$') AS email_domain
    FROM sampled_customers AS c
    JOIN tpcds.store_returns AS sr
        ON sr.sr_customer_sk = c.c_customer_sk
    WHERE
        REGEXP_LIKE(c.c_email_address, '^.+@.+\\.(net|org)$')
        AND c.c_first_name LIKE 'A%'
    GROUP BY
        c.c_customer_id,
        concat(c.c_first_name, ' ', c.c_last_name),
        c.c_email_address
)
SELECT
    customer_id,
    customer_name,
    source,
    total_amount,
    amount_category,
    email_domain
FROM web_sales_agg
UNION ALL
SELECT
    customer_id,
    customer_name,
    source,
    total_amount,
    amount_category,
    email_domain
FROM store_returns_agg
ORDER BY total_amount DESC
LIMIT 100
