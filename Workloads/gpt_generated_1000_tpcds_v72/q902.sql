WITH customer_sales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_state,
        SUM(ss.ss_net_paid) AS total_paid,
        AVG(ss.ss_ext_discount_amt) AS avg_discount,
        COUNT(*) AS sale_cnt,
        SUM(CASE WHEN ss.ss_ext_discount_amt > 500 THEN 1 ELSE 0 END) AS high_discount_cnt
    FROM store_sales ss
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE
        ca.ca_gmt_offset = -5.00
        AND ca.ca_state = 'CA'
        AND c.c_birth_year BETWEEN 1970 AND 1990
        AND c.c_last_review_date > 2452300
        AND ss.ss_ext_discount_amt >= 0
        AND ss.ss_list_price < 200
    GROUP BY
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_state
)
SELECT
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.ca_state,
    cs.total_paid,
    cs.avg_discount,
    cs.sale_cnt,
    cs.high_discount_cnt,
    ROW_NUMBER() OVER (PARTITION BY cs.ca_state ORDER BY cs.total_paid DESC) AS state_rank,
    CASE
        WHEN cs.avg_discount > (SELECT AVG(ss2.ss_ext_discount_amt) FROM store_sales ss2) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS discount_category
FROM customer_sales cs
WHERE NOT EXISTS (
    SELECT 1
    FROM store_sales ss3
    WHERE ss3.ss_customer_sk = cs.c_customer_sk
      AND ss3.ss_sold_date_sk > 2452500
)
ORDER BY cs.total_paid DESC
LIMIT 100
