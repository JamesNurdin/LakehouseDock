WITH customer_sales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_preferred_cust_flag,
        c.c_birth_year,
        SUM(ss.ss_net_paid) AS total_net_paid,
        COUNT(DISTINCT ss.ss_ticket_number) AS tickets_cnt,
        MAX(ss.ss_ext_discount_amt) AS max_discount_amt
    FROM tpcds.customer c
    JOIN tpcds.store_sales ss
        ON ss.ss_customer_sk = c.c_customer_sk
    WHERE ss.ss_ext_discount_amt > 1000
      AND ss.ss_wholesale_cost < 100
      AND c.c_birth_year BETWEEN 1950 AND 1965
      AND c.c_preferred_cust_flag = 'Y'
    GROUP BY
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_preferred_cust_flag,
        c.c_birth_year
    HAVING SUM(ss.ss_net_paid) > 5000
)
SELECT
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.total_net_paid,
    cs.tickets_cnt,
    cs.max_discount_amt,
    RANK() OVER (ORDER BY cs.total_net_paid DESC) AS revenue_rank,
    CASE
        WHEN cs.tickets_cnt > 10 THEN 'High Frequency'
        ELSE 'Regular'
    END AS customer_segment,
    (
        SELECT COUNT(*)
        FROM tpcds.store_sales ss3
        WHERE ss3.ss_customer_sk = cs.c_customer_sk
          AND ss3.ss_ext_discount_amt > 2000
    ) AS high_discount_txn_cnt
FROM customer_sales cs
WHERE EXISTS (
    SELECT 1
    FROM tpcds.web_page wp
    WHERE wp.wp_customer_sk = cs.c_customer_sk
      AND wp.wp_rec_start_date >= DATE '2000-01-01'
      AND wp.wp_type = 'product'
)
ORDER BY cs.total_net_paid DESC, cs.c_customer_sk
LIMIT 100
