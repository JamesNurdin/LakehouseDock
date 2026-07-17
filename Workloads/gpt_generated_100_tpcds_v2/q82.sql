WITH customer_profit AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(cs.cs_order_number) AS order_cnt
    FROM tpcds.catalog_sales cs
    JOIN tpcds.customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 9 AND 17
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
)
SELECT
    cp.c_customer_id,
    cp.c_first_name,
    cp.c_last_name,
    cp.total_profit,
    cp.order_cnt
FROM customer_profit cp
WHERE cp.total_profit > (SELECT AVG(total_profit) FROM customer_profit)
ORDER BY cp.total_profit DESC
LIMIT 20
