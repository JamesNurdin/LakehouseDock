/* goal: Calculate promotional sales performance for male customers whose email addresses end with example.com, using regex and LIKE filters, and summarize per promotion */
WITH sales_filtered AS (
    SELECT
        ss.ss_promo_sk,
        ss.ss_customer_sk,
        ss.ss_ext_sales_price,
        ss.ss_quantity,
        c.c_salutation,
        c.c_last_name,
        c.c_email_address,
        p.p_promo_name
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE
        REGEXP_LIKE(c.c_email_address, '@example\\.com$')
        AND c.c_salutation LIKE 'Mr.%'
        AND p.p_channel_email = 'Y'
)
SELECT
    p_promo_name,
    COUNT(DISTINCT ss_customer_sk) AS distinct_customers,
    SUM(ss_ext_sales_price) AS total_sales,
    AVG(ss_quantity) AS avg_quantity,
    MIN(CONCAT(c_salutation, ' ', c_last_name)) AS sample_customer_title,
    REGEXP_EXTRACT(c_email_address, '@(.+)$', 1) AS email_domain
FROM sales_filtered
GROUP BY
    p_promo_name,
    REGEXP_EXTRACT(c_email_address, '@(.+)$', 1)
ORDER BY total_sales DESC
LIMIT 100
