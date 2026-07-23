WITH distinct_promos AS (
    SELECT DISTINCT p.p_promo_sk, p.p_promo_id, p.p_channel_dmail, p.p_discount_active
    FROM promotion p
    WHERE p.p_channel_dmail = 'Y'
      AND p.p_discount_active = 'Y'
),
filtered_sales AS (
    SELECT 
        cs.cs_order_number,
        cs.cs_call_center_sk,
        cs.cs_ship_mode_sk,
        cs.cs_promo_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_net_paid_inc_ship_tax,
        cs.cs_quantity
    FROM catalog_sales cs
    WHERE cs.cs_net_paid_inc_ship_tax > 1000
      AND cs.cs_quantity >= 2
),
sales_agg AS (
    SELECT 
        cc.cc_call_center_id,
        cc.cc_name,
        sm.sm_type,
        p.p_promo_id,
        cd.cd_gender,
        SUM(fs.cs_net_paid_inc_ship_tax) AS total_net_paid,
        COUNT(*) AS num_orders,
        (
            SELECT MAX(ws.ws_net_paid_inc_ship_tax)
            FROM web_sales ws
            WHERE ws.ws_promo_sk = p.p_promo_sk
              AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
              AND ws.ws_bill_cdemo_sk = cd.cd_demo_sk
              AND ws.ws_net_paid_inc_ship_tax > 500
        ) AS max_ws_net_paid
    FROM filtered_sales fs
    JOIN distinct_promos p ON fs.cs_promo_sk = p.p_promo_sk
    JOIN call_center cc ON fs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON fs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_demographics cd ON fs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cc.cc_state = 'CA'
      AND cd.cd_marital_status = 'M'
      AND sm.sm_type = 'AIR'
      AND EXISTS (
          SELECT 1
          FROM web_sales ws
          WHERE ws.ws_promo_sk = p.p_promo_sk
            AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
            AND ws.ws_bill_cdemo_sk = cd.cd_demo_sk
            AND ws.ws_net_paid_inc_ship_tax > 1000
      )
    GROUP BY 
        cc.cc_call_center_id,
        cc.cc_name,
        sm.sm_type,
        p.p_promo_id,
        cd.cd_gender,
        p.p_promo_sk,
        sm.sm_ship_mode_sk,
        cd.cd_demo_sk
)
SELECT 
    cc_call_center_id,
    cc_name,
    sm_type,
    p_promo_id,
    cd_gender,
    total_net_paid,
    num_orders,
    CASE 
        WHEN total_net_paid > 50000 THEN 'HIGH'
        WHEN total_net_paid BETWEEN 20000 AND 50000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS net_paid_category,
    max_ws_net_paid,
    RANK() OVER (PARTITION BY sm_type ORDER BY total_net_paid DESC) AS rank_within_ship_type
FROM sales_agg
ORDER BY total_net_paid DESC
LIMIT 100
