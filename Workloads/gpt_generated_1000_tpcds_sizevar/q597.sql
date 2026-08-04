WITH order_intersect AS (
        SELECT cs_order_number FROM catalog_sales WHERE cs_quantity > 10
        INTERSECT
        SELECT cs_order_number FROM catalog_sales WHERE cs_net_profit > 200
    ),
    order_exclude AS (
        SELECT cs_order_number FROM catalog_sales
        WHERE cs_ship_mode_sk = (
            SELECT sm_ship_mode_sk FROM ship_mode WHERE sm_carrier = 'TBS' LIMIT 1
        )
    ),
    filtered_orders AS (
        SELECT cs_order_number FROM order_intersect
        EXCEPT
        SELECT cs_order_number FROM order_exclude
    )
SELECT
    cs.cs_order_number,
    cs.cs_net_profit,
    cc.cc_name,
    cc.cc_state,
    cp.cp_department,
    sm.sm_carrier,
    cd.cd_gender,
    RANK() OVER (PARTITION BY cc.cc_state ORDER BY cs.cs_net_profit DESC) AS profit_rank_state,
    (
        SELECT COUNT(*)
        FROM catalog_sales cs2
        WHERE cs2.cs_call_center_sk = cs.cs_call_center_sk
    ) AS total_sales_per_cc,
    CASE
        WHEN cs.cs_ext_discount_amt > 1000 THEN 'HIGH_DISCOUNT'
        ELSE 'NORMAL'
    END AS discount_category
FROM catalog_sales cs
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
WHERE
    cc.cc_state = 'TX'
    AND cp.cp_department = 'Sports'
    AND sm.sm_carrier IN ('UPS', 'BOXBUNDLES')
    AND cd.cd_dep_employed_count >= 2
    AND cs.cs_net_profit > 0
    AND cs.cs_order_number IN (SELECT cs_order_number FROM filtered_orders)
    AND NOT EXISTS (
        SELECT 1 FROM promotion p2
        WHERE p2.p_promo_sk = cs.cs_promo_sk
          AND p2.p_discount_active = 'Y'
    )
ORDER BY profit_rank_state, cs.cs_net_profit DESC
LIMIT 100
