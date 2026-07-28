WITH sales_by_store_hour AS (
    SELECT
        s.s_store_id,
        s.s_state,
        t.t_hour,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS txn_count
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE
        ss.ss_wholesale_cost > 30.00
        AND ca.ca_state = 'CA'
        AND (t.t_minute IS NULL OR t.t_minute >= 10)
    GROUP BY s.s_store_id, s.s_state, t.t_hour
)
SELECT
    s_store_id,
    s_state,
    AVG(total_profit) AS avg_hourly_profit,
    SUM(txn_count) AS total_transactions
FROM sales_by_store_hour
WHERE total_profit > 1000
GROUP BY s_store_id, s_state
HAVING SUM(txn_count) > 10
ORDER BY avg_hourly_profit DESC
LIMIT 20
