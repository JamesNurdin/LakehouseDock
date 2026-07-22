WITH filtered_sales AS (
    SELECT
        ss.ss_customer_sk,
        ss.ss_sold_time_sk,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_ext_discount_amt,
        ss.ss_net_paid,
        ss.ss_net_profit,
        c.c_customer_id,
        c.c_last_review_date,
        c.c_first_sales_date_sk,
        t.t_hour
    FROM store_sales ss
    INNER JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    INNER JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE c.c_last_review_date >= 2452400
      AND c.c_first_sales_date_sk BETWEEN 2449000 AND 2452000
      AND t.t_hour IN (0, 2, 10, 3)
      AND ss.ss_ext_discount_amt > 300
      AND ss.ss_ext_wholesale_cost < 1000
)
SELECT
    c_customer_id,
    CASE WHEN t_hour < 12 THEN 'Morning' ELSE 'Afternoon' END AS time_of_day,
    COUNT(*) AS transaction_count,
    SUM(ss_quantity) AS total_quantity,
    SUM(ss_ext_sales_price) AS total_sales,
    AVG(ss_net_paid) AS avg_net_paid,
    SUM(CASE WHEN ss_ext_discount_amt > 500 THEN ss_ext_sales_price ELSE 0 END) AS high_discount_sales,
    MIN(ss_net_profit) AS min_profit,
    MAX(ss_net_profit) AS max_profit
FROM filtered_sales
GROUP BY c_customer_id,
         CASE WHEN t_hour < 12 THEN 'Morning' ELSE 'Afternoon' END
HAVING SUM(ss_ext_sales_price) > 10000
ORDER BY total_sales DESC
LIMIT 100
