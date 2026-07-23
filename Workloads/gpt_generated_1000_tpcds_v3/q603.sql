WITH cs_agg AS (
    SELECT
        cs_call_center_sk,
        cs_promo_sk,
        cs_bill_cdemo_sk,
        cs_ship_cdemo_sk,
        SUM(cs_net_paid_inc_ship_tax) AS total_net_paid_inc_ship_tax,
        SUM(cs_quantity) AS total_quantity,
        AVG(cs_ext_discount_amt) AS avg_discount,
        SUM(cs_net_profit) AS total_net_profit,
        CASE
            WHEN SUM(cs_net_profit) > 50000 THEN 'High'
            WHEN SUM(cs_net_profit) > 20000 THEN 'Medium'
            ELSE 'Low'
        END AS profit_tier
    FROM catalog_sales
    WHERE cs_net_paid_inc_ship_tax > 1000
      AND cs_ext_ship_cost < 5000
    GROUP BY cs_call_center_sk, cs_promo_sk, cs_bill_cdemo_sk, cs_ship_cdemo_sk
)
SELECT
    cc.cc_name,
    p.p_promo_name,
    cd_bill.cd_gender AS bill_gender,
    cd_ship.cd_gender AS ship_gender,
    csagg.total_net_paid_inc_ship_tax,
    csagg.total_quantity,
    csagg.avg_discount,
    csagg.total_net_profit,
    csagg.profit_tier,
    ROW_NUMBER() OVER (PARTITION BY cc.cc_name ORDER BY csagg.total_net_paid_inc_ship_tax DESC) AS rn_by_center,
    RANK() OVER (ORDER BY csagg.total_net_profit DESC) AS global_profit_rank
FROM cs_agg csagg
JOIN call_center cc ON csagg.cs_call_center_sk = cc.cc_call_center_sk
JOIN promotion p ON csagg.cs_promo_sk = p.p_promo_sk
JOIN customer_demographics cd_bill ON csagg.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_demographics cd_ship ON csagg.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
WHERE cc.cc_state = 'CA'
  AND p.p_response_target = 1
  AND cc.cc_gmt_offset >= 0
  AND cd_bill.cd_dep_employed_count >= 2
ORDER BY csagg.total_net_paid_inc_ship_tax DESC
LIMIT 100
