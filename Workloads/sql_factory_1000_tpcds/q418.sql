WITH cc_total_profit AS (
    SELECT
        cs.cs_call_center_sk,
        SUM(cs.cs_net_profit) AS cc_total_profit
    FROM catalog_sales cs
    GROUP BY cs.cs_call_center_sk
),
item_cc_profit_agg AS (
    SELECT
        cs.cs_call_center_sk,
        cs.cs_item_sk,
        SUM(cs.cs_net_profit) AS item_profit
    FROM catalog_sales cs
    GROUP BY cs.cs_call_center_sk, cs.cs_item_sk
),
item_cc_profit AS (
    SELECT
        icp.cs_call_center_sk,
        icp.cs_item_sk,
        icp.item_profit,
        ROW_NUMBER() OVER (PARTITION BY icp.cs_call_center_sk ORDER BY icp.item_profit DESC) AS profit_rank
    FROM item_cc_profit_agg icp
),
item_cc_ship_mode_counts AS (
    SELECT
        cs.cs_call_center_sk,
        cs.cs_item_sk,
        cs.cs_ship_mode_sk,
        COUNT(*) AS mode_cnt
    FROM catalog_sales cs
    GROUP BY cs.cs_call_center_sk, cs.cs_item_sk, cs.cs_ship_mode_sk
),
item_cc_ship_mode AS (
    SELECT
        smc.cs_call_center_sk,
        smc.cs_item_sk,
        smc.cs_ship_mode_sk,
        smc.mode_cnt,
        ROW_NUMBER() OVER (PARTITION BY smc.cs_call_center_sk, smc.cs_item_sk ORDER BY smc.mode_cnt DESC) AS rn
    FROM item_cc_ship_mode_counts smc
)
SELECT
    cc.cc_call_center_id,
    cc.cc_name,
    i.i_item_id,
    i.i_product_name,
    icp.item_profit,
    icp.profit_rank,
    CASE
        WHEN icp.item_profit / ctp.cc_total_profit > 0.20 THEN 'High'
        WHEN icp.item_profit / ctp.cc_total_profit > 0.10 THEN 'Medium'
        ELSE 'Low'
    END AS profit_share_category,
    sm.sm_ship_mode_id AS dominant_ship_mode,
    ROUND(icp.item_profit / ctp.cc_total_profit * 100, 2) AS profit_share_pct
FROM item_cc_profit icp
JOIN cc_total_profit ctp
    ON ctp.cs_call_center_sk = icp.cs_call_center_sk
JOIN call_center cc
    ON cc.cc_call_center_sk = icp.cs_call_center_sk
JOIN item i
    ON i.i_item_sk = icp.cs_item_sk
LEFT JOIN item_cc_ship_mode smc
    ON smc.cs_call_center_sk = icp.cs_call_center_sk
    AND smc.cs_item_sk = icp.cs_item_sk
    AND smc.rn = 1
LEFT JOIN ship_mode sm
    ON sm.sm_ship_mode_sk = smc.cs_ship_mode_sk
WHERE icp.profit_rank <= 5
ORDER BY cc.cc_call_center_id, icp.profit_rank
