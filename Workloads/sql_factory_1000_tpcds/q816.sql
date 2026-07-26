SELECT
    cs.cs_sold_date_sk,
    p.p_promo_name,
    sm.sm_ship_mode_id,
    cd.cd_gender,
    SUM(cs.cs_net_profit) AS daily_net_profit,
    LAG(SUM(cs.cs_net_profit)) OVER (PARTITION BY p.p_promo_name, sm.sm_ship_mode_id ORDER BY cs.cs_sold_date_sk) AS prev_day_net_profit,
    SUM(cs.cs_net_profit) - LAG(SUM(cs.cs_net_profit)) OVER (PARTITION BY p.p_promo_name, sm.sm_ship_mode_id ORDER BY cs.cs_sold_date_sk) AS profit_change,
    CASE
        WHEN SUM(cs.cs_net_profit) - LAG(SUM(cs.cs_net_profit)) OVER (PARTITION BY p.p_promo_name, sm.sm_ship_mode_id ORDER BY cs.cs_sold_date_sk) > 0 THEN 'Increase'
        WHEN SUM(cs.cs_net_profit) - LAG(SUM(cs.cs_net_profit)) OVER (PARTITION BY p.p_promo_name, sm.sm_ship_mode_id ORDER BY cs.cs_sold_date_sk) < 0 THEN 'Decrease'
        ELSE 'No Change'
    END AS change_indicator
FROM catalog_sales cs
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer_demographics cd ON cs.cs_ship_cdemo_sk = cd.cd_demo_sk
GROUP BY cs.cs_sold_date_sk, p.p_promo_name, sm.sm_ship_mode_id, cd.cd_gender
ORDER BY p.p_promo_name, sm.sm_ship_mode_id, cs.cs_sold_date_sk
