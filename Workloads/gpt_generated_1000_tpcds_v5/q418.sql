WITH filtered_sales AS (
    SELECT
        cs.cs_sold_time_sk,
        cs.cs_call_center_sk,
        cs.cs_ship_mode_sk,
        cs.cs_net_profit
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE td.t_meal_time = 'lunch'
      AND cc.cc_county LIKE '%County'
      AND regexp_like(sm.sm_contract, '^.{2}[0-9]')
      AND substring(cc.cc_street_type, 1, 2) = 'St'
)
SELECT
    cc.cc_call_center_id,
    sm.sm_code,
    regexp_extract(sm.sm_carrier, '^([A-Z]+)', 1) AS carrier_prefix,
    SUM(fs.cs_net_profit) AS total_profit,
    COUNT(CASE WHEN fs.cs_net_profit > 1000 THEN 1 END) AS high_profit_sales,
    CASE
        WHEN SUM(fs.cs_net_profit) > 50000 THEN 'Top'
        WHEN SUM(fs.cs_net_profit) > 10000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_tier
FROM filtered_sales fs
JOIN call_center cc ON fs.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm ON fs.cs_ship_mode_sk = sm.sm_ship_mode_sk
GROUP BY
    cc.cc_call_center_id,
    sm.sm_code,
    regexp_extract(sm.sm_carrier, '^([A-Z]+)', 1)
HAVING SUM(fs.cs_net_profit) > 1000
ORDER BY total_profit DESC
LIMIT 100
