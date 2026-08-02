WITH profit_by_cc AS (
    SELECT 
        cc.cc_call_center_sk,
        cc.cc_call_center_id,
        cc.cc_name,
        SUM(cs.cs_net_profit) AS total_net_profit,
        CASE
            WHEN SUM(cs.cs_net_profit) >= 10000 THEN 'HIGH'
            WHEN SUM(cs.cs_net_profit) >= 0 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS profit_category
    FROM call_center cc
    JOIN catalog_sales cs ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'
    GROUP BY cc.cc_call_center_sk, cc.cc_call_center_id, cc.cc_name
),
high_cc AS (
    SELECT DISTINCT cc_call_center_id, cc_name, total_net_profit, profit_category
    FROM profit_by_cc
    WHERE profit_category = 'HIGH'
),
low_cc AS (
    SELECT DISTINCT cc_call_center_id, cc_name, total_net_profit, profit_category
    FROM profit_by_cc
    WHERE profit_category = 'LOW'
)
SELECT *
FROM (
    SELECT cc_call_center_id, cc_name, total_net_profit, profit_category
    FROM high_cc
    EXCEPT
    SELECT cc_call_center_id, cc_name, total_net_profit, profit_category
    FROM low_cc
) AS result
ORDER BY total_net_profit DESC
LIMIT 100
