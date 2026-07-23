WITH sales_cust AS (
    SELECT
        ss.ss_customer_sk,
        ss.ss_item_sk,
        ss.ss_store_sk,
        ss.ss_sales_price,
        ss.ss_net_paid,
        ss.ss_net_profit,
        ss.ss_wholesale_cost,
        ss.ss_coupon_amt,
        c.c_birth_country,
        c.c_customer_id
    FROM store_sales ss
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    WHERE ss.ss_wholesale_cost IS NOT NULL
)
SELECT
    c_birth_country,
    num_customers,
    total_net_paid,
    total_net_profit
FROM (
    SELECT
        c_birth_country,
        COUNT(DISTINCT c_customer_id) AS num_customers,
        SUM(ss_net_paid) AS total_net_paid,
        SUM(ss_net_profit) AS total_net_profit
    FROM sales_cust
    WHERE c_birth_country = 'SWITZERLAND'
      AND ss_wholesale_cost > 50
    GROUP BY c_birth_country
    HAVING SUM(ss_net_paid) > 10000

    UNION ALL

    SELECT
        c_birth_country,
        COUNT(DISTINCT c_customer_id) AS num_customers,
        SUM(ss_net_paid) AS total_net_paid,
        SUM(ss_net_profit) AS total_net_profit
    FROM sales_cust
    WHERE c_birth_country = 'KOREA'
      AND ss_coupon_amt > 1000
    GROUP BY c_birth_country
    HAVING SUM(ss_net_paid) > 10000
) AS combined
ORDER BY total_net_paid DESC
LIMIT 100
