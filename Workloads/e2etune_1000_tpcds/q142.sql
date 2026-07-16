WITH daily_sales AS (
    SELECT
        cs.cs_ship_date_sk,
        sm.sm_ship_mode_id,
        sm.sm_carrier,
        SUM(cs.cs_net_profit) AS daily_net_profit,
        AVG(cs.cs_ext_ship_cost) AS avg_ship_cost,
        SUM(cs.cs_quantity) AS total_quantity,
        COUNT(*) AS transaction_cnt
    FROM catalog_sales cs
    JOIN ship_mode sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cs.cs_ext_ship_cost >= 200
      AND cs.cs_ship_date_sk BETWEEN 2450840 AND 2450906
    GROUP BY cs.cs_ship_date_sk, sm.sm_ship_mode_id, sm.sm_carrier
)
SELECT
    ds.cs_ship_date_sk,
    ds.sm_ship_mode_id,
    ds.sm_carrier,
    ds.daily_net_profit,
    ds.avg_ship_cost,
    ds.total_quantity,
    ds.transaction_cnt,
    RANK() OVER (PARTITION BY ds.cs_ship_date_sk ORDER BY ds.daily_net_profit DESC) AS profit_rank
FROM daily_sales ds
WHERE ds.daily_net_profit > 0
ORDER BY ds.cs_ship_date_sk ASC, profit_rank ASC
LIMIT 100
