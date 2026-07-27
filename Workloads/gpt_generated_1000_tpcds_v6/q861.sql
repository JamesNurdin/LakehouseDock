WITH promo_filtered AS (
    SELECT p_promo_sk
    FROM promotion
    WHERE regexp_like(p_promo_name, '^Summer.*')
      AND p_discount_active = 'Y'
)
SELECT
    sm.sm_carrier,
    cp.cp_department,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    SUM(cs.cs_net_profit) AS total_profit,
    AVG(cs.cs_net_profit) AS avg_profit
FROM catalog_sales cs
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
WHERE
    regexp_like(cp.cp_description, '(Special|Discount)')
    AND cp.cp_type LIKE 'A%'
    AND cd.cd_credit_rating = 'Good'
    AND cd.cd_dep_employed_count > 2
    AND cs.cs_promo_sk IN (SELECT p_promo_sk FROM promo_filtered)
GROUP BY sm.sm_carrier, cp.cp_department
ORDER BY total_profit DESC
LIMIT 100
