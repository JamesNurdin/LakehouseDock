WITH daily_profit AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_name,
        cs.cs_sold_date_sk,
        SUM(cs.cs_net_profit) AS daily_net_profit,
        COUNT(DISTINCT CASE WHEN p.p_channel_tv = 'Y' THEN p.p_promo_sk END) AS tv_promo_cnt
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE p.p_discount_active = 'Y'
    GROUP BY cc.cc_call_center_id, cc.cc_name, cs.cs_sold_date_sk
)
SELECT
    cc_call_center_id,
    cc_name,
    cs_sold_date_sk,
    daily_net_profit,
    LAG(daily_net_profit) OVER (PARTITION BY cc_call_center_id ORDER BY cs_sold_date_sk) AS previous_day_profit,
    CASE
        WHEN daily_net_profit > LAG(daily_net_profit) OVER (PARTITION BY cc_call_center_id ORDER BY cs_sold_date_sk) THEN 'Increasing'
        WHEN daily_net_profit < LAG(daily_net_profit) OVER (PARTITION BY cc_call_center_id ORDER BY cs_sold_date_sk) THEN 'Decreasing'
        ELSE 'Stable'
    END AS profit_trend,
    tv_promo_cnt
FROM daily_profit
ORDER BY cc_call_center_id, cs_sold_date_sk
LIMIT 100
