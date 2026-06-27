WITH customer_sales AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(*) AS transaction_count,
        AVG(ss.ss_quantity) AS avg_quantity
    FROM
        customer c
        JOIN store_sales ss
            ON ss.ss_customer_sk = c.c_customer_sk
    WHERE
        c.c_preferred_cust_flag = 'Y'
    GROUP BY
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name
    HAVING
        COUNT(*) > 5
)
SELECT
    cs.c_customer_id,
    cs.c_first_name,
    cs.c_last_name,
    cs.total_net_paid,
    cs.total_net_profit,
    cs.transaction_count,
    cs.avg_quantity,
    RANK() OVER (ORDER BY cs.total_net_paid DESC) AS net_paid_rank,
    CAST(cs.total_net_paid AS double) / SUM(cs.total_net_paid) OVER () AS net_paid_pct
FROM
    customer_sales cs
ORDER BY
    cs.total_net_paid DESC
LIMIT 10
