SELECT
    cd.cd_gender,
    cd.cd_marital_status,
    sm.sm_type,
    p.p_promo_name,
    COUNT(*) AS sales_count,
    AVG(cs.cs_ext_discount_amt) AS avg_discount,
    SUM(cs.cs_net_paid) AS total_net_paid,
    DENSE_RANK() OVER (PARTITION BY sm.sm_type ORDER BY SUM(cs.cs_net_paid) DESC) AS net_paid_rank
FROM catalog_sales cs
JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
GROUP BY cd.cd_gender, cd.cd_marital_status, sm.sm_type, p.p_promo_name
ORDER BY sm.sm_type, net_paid_rank
