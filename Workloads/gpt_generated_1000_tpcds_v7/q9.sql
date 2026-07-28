WITH cust_sales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM customer c
    JOIN store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
)
SELECT
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.total_profit,
    CASE WHEN cs.total_profit > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_flag,
    (
        SELECT COUNT(*)
        FROM store_sales ss2
        WHERE ss2.ss_customer_sk = cs.c_customer_sk
          AND ss2.ss_net_profit > 0
    ) AS txn_cnt
FROM cust_sales cs
WHERE cs.total_profit > 0

UNION ALL

SELECT
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.total_profit,
    CASE WHEN cs.total_profit > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_flag,
    (
        SELECT COUNT(*)
        FROM store_sales ss2
        WHERE ss2.ss_customer_sk = cs.c_customer_sk
          AND ss2.ss_net_profit <= 0
    ) AS txn_cnt
FROM cust_sales cs
WHERE cs.total_profit <= 0

ORDER BY total_profit DESC
LIMIT 100
