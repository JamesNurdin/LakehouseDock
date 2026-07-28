WITH sub1 AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_call_center_id,
        cc.cc_state,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_net_profit,
        CASE
            WHEN SUM(cs.cs_net_profit) / NULLIF(SUM(cs.cs_net_paid), 0) > 0.20 THEN 'HIGH'
            WHEN SUM(cs.cs_net_profit) / NULLIF(SUM(cs.cs_net_paid), 0) > 0.10 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS profit_category,
        (
            SELECT AVG(cs2.cs_ext_ship_cost)
            FROM catalog_sales cs2
            WHERE cs2.cs_call_center_sk = cc.cc_call_center_sk
        ) AS avg_ship_cost
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE cc.cc_state = 'CA'
      AND cs.cs_ext_ship_cost > 500
    GROUP BY cc.cc_call_center_sk, cc.cc_call_center_id, cc.cc_state
    HAVING SUM(cs.cs_net_paid) > 10000
),
sub2 AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_call_center_id,
        cc.cc_state,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_net_profit,
        CASE
            WHEN SUM(cs.cs_net_profit) / NULLIF(SUM(cs.cs_net_paid), 0) > 0.20 THEN 'HIGH'
            WHEN SUM(cs.cs_net_profit) / NULLIF(SUM(cs.cs_net_paid), 0) > 0.10 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS profit_category,
        (
            SELECT AVG(cs2.cs_ext_ship_cost)
            FROM catalog_sales cs2
            WHERE cs2.cs_call_center_sk = cc.cc_call_center_sk
        ) AS avg_ship_cost
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE cc.cc_state = 'TX'
      AND cs.cs_ext_ship_cost <= 500
    GROUP BY cc.cc_call_center_sk, cc.cc_call_center_id, cc.cc_state
    HAVING SUM(cs.cs_net_paid) > 10000
)
SELECT
    combined.cc_call_center_sk,
    combined.cc_call_center_id,
    combined.cc_state,
    combined.total_net_paid,
    combined.total_net_profit,
    combined.profit_category,
    combined.avg_ship_cost
FROM (
    SELECT * FROM sub1
    UNION ALL
    SELECT * FROM sub2
) AS combined
WHERE NOT EXISTS (
    SELECT 1
    FROM call_center cc_ex
    WHERE cc_ex.cc_call_center_sk = combined.cc_call_center_sk
      AND cc_ex.cc_employees > 5000000
)
LIMIT 100
