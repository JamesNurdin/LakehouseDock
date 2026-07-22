WITH filtered_sales AS (
    SELECT
        ss.ss_customer_sk,
        ss.ss_net_paid,
        ss.ss_ext_discount_amt,
        ss.ss_quantity,
        ss.ss_sales_price,
        c.c_birth_month,
        c.c_birth_year,
        c.c_first_sales_date_sk,
        c.c_email_address
    FROM tpcds.store_sales ss
    INNER JOIN tpcds.customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    WHERE
        ss.ss_ext_list_price > 1000.00
        AND ss.ss_coupon_amt < 2000.00
        AND ss.ss_list_price BETWEEN 50.00 AND 120.00
        AND c.c_birth_month IN (1, 5, 8)
        AND c.c_first_sales_date_sk BETWEEN 2450391 AND 2451825
        AND c.c_email_address LIKE '%@%.edu'
        AND ss.ss_quantity >= 2
)
SELECT
    c_birth_month,
    c_birth_year,
    SUM(ss_net_paid) AS total_net_paid,
    AVG(ss_ext_discount_amt) AS avg_discount_amt,
    SUM(ss_quantity) AS total_quantity,
    COUNT(DISTINCT ss_customer_sk) AS distinct_customers,
    MIN(ss_sales_price) AS min_sales_price,
    MAX(ss_sales_price) AS max_sales_price
FROM filtered_sales
GROUP BY c_birth_month, c_birth_year
ORDER BY total_net_paid DESC
LIMIT 100
