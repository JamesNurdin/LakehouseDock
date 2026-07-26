SELECT
    cc_call_center_id,
    cc_name,
    cc_city,
    total_net_profit,
    CASE
        WHEN total_net_profit >= 50000 THEN 'Very High'
        WHEN total_net_profit >= 20000 THEN 'High'
        WHEN total_net_profit >= 0 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank
FROM (
    SELECT
        cc.cc_call_center_id,
        cc.cc_name,
        cc.cc_city,
        SUM(cs.cs_net_profit) AS total_net_profit
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE p.p_discount_active = 'Y'
    GROUP BY cc.cc_call_center_id, cc.cc_name, cc.cc_city
) sub
ORDER BY total_net_profit DESC
LIMIT 10
