WITH filtered_customers AS (
    SELECT
        c.c_customer_sk,
        c.c_email_address,
        c.c_first_name,
        c.c_last_name,
        REGEXP_EXTRACT(c.c_email_address, '@([^.]*)\\.', 1) AS email_domain,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name
    FROM
        tpcds.customer c
    WHERE
        REGEXP_LIKE(c.c_email_address, '^[A-Za-z]+\\.[A-Za-z]+@[^@]+\\.com$')
        AND c.c_preferred_cust_flag = 'Y'
        AND SUBSTRING(c.c_email_address, 1, 3) = 'Ros'
),
filtered_returns AS (
    SELECT
        fc.c_customer_sk,
        fc.email_domain,
        fc.full_name,
        sr.sr_return_amt,
        sr.sr_net_loss,
        s.s_store_name,
        s.s_store_sk,
        d.d_year,
        d.d_moy,
        wp.wp_url
    FROM
        filtered_customers fc
        JOIN tpcds.store_returns sr ON sr.sr_customer_sk = fc.c_customer_sk
        JOIN tpcds.store s ON sr.sr_store_sk = s.s_store_sk
        JOIN tpcds.date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        LEFT JOIN tpcds.web_page wp ON wp.wp_customer_sk = fc.c_customer_sk
            AND wp.wp_access_date_sk = d.d_date_sk
    WHERE
        s.s_store_name LIKE '%Store%'
        AND (wp.wp_url IS NULL OR wp.wp_url LIKE '%promo%')
)
SELECT
    s_store_name,
    d_year,
    d_moy AS month,
    email_domain,
    COUNT(DISTINCT c_customer_sk) AS distinct_customers,
    SUM(sr_return_amt) AS total_return_amount,
    SUM(sr_net_loss) AS total_net_loss,
    COUNT(DISTINCT wp_url) AS distinct_pages_visited
FROM
    filtered_returns
GROUP BY
    s_store_name,
    d_year,
    d_moy,
    email_domain
ORDER BY
    total_return_amount DESC,
    d_year,
    d_moy
LIMIT 100
