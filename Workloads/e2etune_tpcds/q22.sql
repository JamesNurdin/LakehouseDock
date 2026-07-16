WITH customer_sales AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_salutation,
        c.c_birth_month,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_quantity) AS total_quantity,
        AVG(ss.ss_sales_price) AS avg_sales_price,
        COUNT(*) AS transaction_count
    FROM
        store_sales ss
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE
        c.c_preferred_cust_flag = 'Y'
        AND c.c_birth_month IN (1, 12)
        AND ss.ss_sold_date_sk BETWEEN 2450000 AND 2459999
    GROUP BY
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_salutation,
        c.c_birth_month
)
SELECT
    cs.c_customer_id,
    cs.c_first_name,
    cs.c_last_name,
    cs.c_salutation,
    cs.c_birth_month,
    cs.total_net_profit,
    cs.total_sales,
    cs.total_quantity,
    cs.avg_sales_price,
    cs.transaction_count,
    RANK() OVER (PARTITION BY cs.c_salutation ORDER BY cs.total_net_profit DESC) AS salutation_rank
FROM
    customer_sales cs
WHERE
    cs.total_net_profit > 0
ORDER BY
    cs.total_net_profit DESC
LIMIT 10
