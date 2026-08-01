WITH union_sales AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_sold_date_sk,
        ss.ss_net_profit,
        ss.ss_coupon_amt,
        td.t_hour,
        'LOW_COST' AS cost_bucket
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE ss.ss_wholesale_cost <= 30
    UNION ALL
    SELECT
        ss.ss_store_sk,
        ss.ss_sold_date_sk,
        ss.ss_net_profit,
        ss.ss_coupon_amt,
        td.t_hour,
        'HIGH_COST' AS cost_bucket
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE ss.ss_wholesale_cost > 30
)
SELECT
    us.ss_store_sk,
    (SELECT s.s_store_name FROM store s WHERE s.s_store_sk = us.ss_store_sk) AS store_name,
    us.t_hour,
    us.cost_bucket,
    SUM(us.ss_net_profit) AS total_net_profit,
    SUM(us.ss_coupon_amt) AS total_coupon_amt,
    COUNT(*) AS transaction_count,
    CASE
        WHEN SUM(us.ss_net_profit) > 0 THEN 'Profit'
        WHEN SUM(us.ss_net_profit) = 0 THEN 'Break-even'
        ELSE 'Loss'
    END AS profit_category,
    RANK() OVER (PARTITION BY us.t_hour ORDER BY SUM(us.ss_net_profit) DESC) AS profit_rank_by_hour,
    (SELECT AVG(ss2.ss_net_profit) FROM store_sales ss2 WHERE ss2.ss_store_sk = us.ss_store_sk) AS avg_store_net_profit
FROM union_sales us
WHERE
    us.t_hour BETWEEN 9 AND 14                                   -- predicate 1
    AND us.ss_coupon_amt < 1000                                   -- predicate 2
    AND us.ss_coupon_amt > 100                                    -- predicate 3
    AND us.ss_net_profit > 0                                      -- predicate 4
    AND EXISTS (                                                  -- semi‑join introduces store
        SELECT 1
        FROM store s
        WHERE s.s_store_sk = us.ss_store_sk
          AND s.s_number_employees > 200                         -- predicate 5
          AND s.s_market_id = 1                                 -- predicate 6
    )
GROUP BY
    us.ss_store_sk,
    us.t_hour,
    us.cost_bucket
ORDER BY
    profit_rank_by_hour,
    total_net_profit DESC
LIMIT 100
