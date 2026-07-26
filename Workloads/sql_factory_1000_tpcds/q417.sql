WITH cc_sales AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_call_center_id,
        cc.cc_name,
        cc.cc_division,
        cc.cc_division_name,
        SUM(cs.cs_net_profit) AS total_net_profit,
        COUNT(*) AS total_transactions
    FROM call_center cc
    JOIN catalog_sales cs ON cs.cs_call_center_sk = cc.cc_call_center_sk
    GROUP BY cc.cc_call_center_sk, cc.cc_call_center_id, cc.cc_name, cc.cc_division, cc.cc_division_name
),
cc_ship_mode_counts AS (
    SELECT
        cs.cs_call_center_sk,
        cs.cs_ship_mode_sk,
        COUNT(*) AS mode_cnt
    FROM catalog_sales cs
    GROUP BY cs.cs_call_center_sk, cs.cs_ship_mode_sk
),
cc_ship_mode AS (
    SELECT
        cs_call_center_sk,
        cs_ship_mode_sk,
        mode_cnt,
        ROW_NUMBER() OVER (PARTITION BY cs_call_center_sk ORDER BY mode_cnt DESC) AS rn
    FROM cc_ship_mode_counts
)
SELECT
    s.cc_call_center_id,
    s.cc_name,
    s.cc_division,
    s.cc_division_name,
    s.total_net_profit,
    s.total_transactions,
    sm.sm_ship_mode_id AS most_frequent_ship_mode,
    CASE
        WHEN s.total_net_profit > 1000000 THEN 'High'
        WHEN s.total_net_profit > 500000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    RANK() OVER (PARTITION BY s.cc_division ORDER BY s.total_net_profit DESC) AS division_profit_rank
FROM cc_sales s
LEFT JOIN cc_ship_mode smc
    ON smc.cs_call_center_sk = s.cc_call_center_sk
    AND smc.rn = 1
LEFT JOIN ship_mode sm
    ON sm.sm_ship_mode_sk = smc.cs_ship_mode_sk
ORDER BY s.cc_division, division_profit_rank
