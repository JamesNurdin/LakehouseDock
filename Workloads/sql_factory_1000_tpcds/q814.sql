SELECT
    cd_bill.cd_gender AS bill_gender,
    cd_bill.cd_marital_status AS bill_marital_status,
    cd_ship.cd_gender AS ship_gender,
    cd_ship.cd_marital_status AS ship_marital_status,
    sm.sm_type AS ship_mode_type,
    SUM(cs.cs_net_profit) AS segment_net_profit,
    AVG(cs.cs_ext_discount_amt) AS avg_discount,
    CASE
        WHEN SUM(cs.cs_net_profit) > 50000 THEN 'HighProfit'
        WHEN SUM(cs.cs_net_profit) > 20000 THEN 'MidProfit'
        ELSE 'LowProfit'
    END AS profit_class,
    ROW_NUMBER() OVER (ORDER BY SUM(cs.cs_net_profit) DESC) AS profit_rank
FROM catalog_sales cs
JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
GROUP BY cd_bill.cd_gender, cd_bill.cd_marital_status, cd_ship.cd_gender, cd_ship.cd_marital_status, sm.sm_type
ORDER BY segment_net_profit DESC
LIMIT 10
