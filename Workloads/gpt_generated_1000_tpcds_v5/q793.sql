WITH sales_joined AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_store_sk,
        ss.ss_cdemo_sk,
        ss.ss_sold_time_sk,
        ss.ss_addr_sk,
        ss.ss_quantity,
        ss.ss_wholesale_cost,
        ss.ss_net_profit,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        t.t_hour,
        t.t_meal_time,
        s.s_store_name,
        s.s_state
    FROM store_sales ss
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    WHERE
        t.t_meal_time = 'dinner'                     -- predicate 1
        AND t.t_hour BETWEEN 17 AND 20               -- predicate 2
        AND cd.cd_marital_status = 'M'               -- predicate 3
        AND cd.cd_purchase_estimate >= 3000          -- predicate 4
        AND s.s_state = 'TX'                         -- predicate 5
        AND ss.ss_wholesale_cost > 20                -- predicate 6
        AND ss.ss_quantity >= 2                      -- predicate 7
)
SELECT
    sj.ss_sold_date_sk,
    sj.s_store_name,
    sj.s_state,
    sj.t_hour,
    sj.t_meal_time,
    sj.cd_gender,
    sj.cd_marital_status,
    sj.cd_purchase_estimate,
    sj.ss_quantity,
    sj.ss_net_profit,
    ROW_NUMBER() OVER (PARTITION BY sj.s_store_name ORDER BY sj.ss_net_profit DESC) AS profit_rank,
    SUM(sj.ss_net_profit) OVER (
        PARTITION BY sj.s_store_name
        ORDER BY sj.ss_sold_date_sk
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_profit
FROM sales_joined sj
WHERE EXISTS (
    SELECT 1
    FROM customer_address ca
    WHERE ca.ca_address_sk = sj.ss_addr_sk
      AND ca.ca_state = 'TX'                 -- predicate 8 (semi‑join filter)
      AND ca.ca_zip LIKE '75%'
)
ORDER BY sj.s_state, profit_rank
LIMIT 100
