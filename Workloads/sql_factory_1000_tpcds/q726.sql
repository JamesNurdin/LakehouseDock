WITH customer_store_profit AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        c.c_customer_id,
        i.i_category,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    GROUP BY s.s_store_sk, s.s_store_name, c.c_customer_id, i.i_category
)
SELECT
    s_store_name,
    c_customer_id,
    i_category,
    total_net_profit,
    total_quantity,
    CASE
        WHEN total_net_profit > 10000 THEN 'Gold'
        WHEN total_net_profit > 5000 THEN 'Silver'
        ELSE 'Bronze'
    END AS profit_tier,
    DENSE_RANK() OVER (PARTITION BY s_store_sk ORDER BY total_net_profit DESC) AS profit_rank
FROM customer_store_profit
ORDER BY s_store_name, profit_rank
LIMIT 10
