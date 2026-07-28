WITH filtered_sales AS (
   SELECT
       cc.cc_state,
       ca.ca_state,
       cd.cd_gender,
       hd.hd_vehicle_count,
       cs.cs_quantity,
       cs.cs_net_profit,
       cs.cs_order_number,
       p.p_channel_email,
       p.p_purpose,
       p.p_discount_active
   FROM catalog_sales cs
   JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
   JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   WHERE cc.cc_state = 'CA'
     AND ca.ca_state = 'CA'
     AND cd.cd_gender = 'F'
     AND cd.cd_education_status = 'College'
     AND hd.hd_vehicle_count >= 0
     AND p.p_channel_email = 'Y'
     AND p.p_purpose = 'Clearance'
     AND cs.cs_quantity > 0
     AND cs.cs_net_profit > 0
     AND EXISTS (
         SELECT 1 FROM promotion p2
         WHERE p2.p_promo_sk = cs.cs_promo_sk
           AND p2.p_discount_active = 'Y'
     )
)
SELECT
    cc_state,
    ca_state,
    cd_gender,
    hd_vehicle_count,
    SUM(cs_net_profit) AS total_profit,
    AVG(cs_quantity) AS avg_quantity,
    COUNT(DISTINCT cs_order_number) AS order_cnt,
    (SELECT AVG(cs3.cs_net_profit) FROM catalog_sales cs3) AS overall_avg_profit
FROM filtered_sales
GROUP BY ROLLUP (cc_state, ca_state, cd_gender, hd_vehicle_count)
ORDER BY total_profit DESC
LIMIT 100
