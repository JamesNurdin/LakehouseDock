WITH customer_sales AS (
    SELECT
        c.c_customer_sk,
        c.c_email_address,
        regexp_extract(c.c_email_address, '@([^.]*)\\.', 1) AS email_domain,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt,
        SUM(ss.ss_ext_sales_price) AS total_sales
    FROM
        tpcds.customer c
    JOIN
        tpcds.store_sales ss
        ON ss.ss_customer_sk = c.c_customer_sk
    WHERE
        regexp_like(c.c_email_address, '^[A-Za-z0-9._%+-]+@.*\\.(com|net|org)$')
        AND c.c_first_name LIKE 'A%'
    GROUP BY
        c.c_customer_sk,
        c.c_email_address,
        regexp_extract(c.c_email_address, '@([^.]*)\\.', 1)
)
SELECT
    cs.c_customer_sk,
    cs.c_email_address,
    cs.email_domain,
    cs.total_profit,
    cs.sales_cnt,
    CASE
        WHEN cs.total_profit > (SELECT AVG(total_profit) FROM customer_sales) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS profit_category,
    CASE
        WHEN cs.total_profit > 100 THEN 'High' ELSE 'Low'
    END AS profit_level
FROM
    customer_sales cs
WHERE EXISTS (
    SELECT 1 FROM tpcds.store_sales ss2
    WHERE ss2.ss_customer_sk = cs.c_customer_sk
      AND ss2.ss_coupon_amt > 0
)
ORDER BY
    cs.total_profit DESC,
    cs.c_email_address
LIMIT 100
