WITH sales_agg AS (
    SELECT
        cs.cs_bill_customer_sk AS customer_sk,
        SUM(cs.cs_ext_sales_price) AS total_sales_amount,
        SUM(cs.cs_quantity) AS total_items_sold,
        SUM(cs.cs_net_paid_inc_ship_tax) AS total_net_paid_inc_ship_tax
    FROM catalog_sales cs
    GROUP BY cs.cs_bill_customer_sk
),
returns_agg AS (
    SELECT
        sr.sr_customer_sk AS customer_sk,
        SUM(sr.sr_return_amt) AS total_return_amount,
        SUM(sr.sr_return_tax) AS total_return_tax,
        SUM(sr.sr_net_loss) AS total_return_loss,
        COUNT(*) AS return_count,
        SUM(CASE WHEN REGEXP_LIKE(r.r_reason_desc, '(?i)damaged') THEN 1 ELSE 0 END) AS damaged_return_count
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    GROUP BY sr.sr_customer_sk
),
email_domains AS (
    SELECT DISTINCT
        c.c_customer_sk,
        REGEXP_EXTRACT(c.c_email_address, '@(.+)$') AS email_domain
    FROM customer c
    WHERE c.c_email_address IS NOT NULL
)
SELECT
    c.c_customer_id,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    ed.email_domain,
    s.total_sales_amount,
    r.total_return_amount,
    (s.total_sales_amount - COALESCE(r.total_return_amount, 0)) AS net_sales_minus_returns,
    r.damaged_return_count
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.customer_sk = r.customer_sk
JOIN customer c
    ON s.customer_sk = c.c_customer_sk
JOIN email_domains ed
    ON c.c_customer_sk = ed.c_customer_sk
WHERE
    REGEXP_LIKE(c.c_email_address, '^.*@example\\.com$')
    AND CONCAT(c.c_first_name, ' ', c.c_last_name) LIKE 'A%'
    AND c.c_customer_sk IN (
        SELECT sr2.sr_customer_sk
        FROM store_returns sr2
        JOIN reason r2 ON sr2.sr_reason_sk = r2.r_reason_sk
        WHERE REGEXP_LIKE(r2.r_reason_desc, '(?i)defective')
    )
ORDER BY net_sales_minus_returns DESC
LIMIT 100
