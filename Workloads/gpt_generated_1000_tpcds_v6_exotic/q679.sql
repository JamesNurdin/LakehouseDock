WITH sales_agg AS (
    SELECT
        cs.cs_warehouse_sk,
        cs.cs_ship_mode_sk,
        cs.cs_bill_hdemo_sk,
        SUM(cs.cs_ext_tax) AS total_ext_tax,
        SUM(cs.cs_net_profit) AS total_net_profit,
        COUNT(*) AS cnt_sales
    FROM catalog_sales cs
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE cs.cs_ext_tax > 20
    GROUP BY cs.cs_warehouse_sk, cs.cs_ship_mode_sk, cs.cs_bill_hdemo_sk
)
SELECT
    w.w_warehouse_name,
    sm.sm_carrier,
    CASE WHEN sm.sm_carrier = 'FEDEX' THEN 'FedEx' ELSE 'Other' END AS carrier_group,
    hd.hd_buy_potential,
    sa.total_ext_tax,
    sa.total_net_profit,
    sa.cnt_sales,
    AVG(ws.ws_net_paid_inc_ship) AS avg_net_paid_inc_ship,
    MIN(ws.ws_net_paid_inc_ship) AS min_net_paid_inc_ship,
    MAX(ws.ws_net_paid_inc_ship) AS max_net_paid_inc_ship
FROM sales_agg sa
JOIN warehouse w ON sa.cs_warehouse_sk = w.w_warehouse_sk
JOIN ship_mode sm ON sa.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN household_demographics hd ON sa.cs_bill_hdemo_sk = hd.hd_demo_sk
LEFT JOIN web_sales ws
    ON ws.ws_warehouse_sk = sa.cs_warehouse_sk
   AND ws.ws_ship_mode_sk = sa.cs_ship_mode_sk
   AND ws.ws_bill_hdemo_sk = sa.cs_bill_hdemo_sk
   AND ws.ws_net_paid_inc_ship > 1500
LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE w.w_state = 'CA'
  AND sm.sm_contract LIKE 'GNJr3g5i7oo%'
  AND hd.hd_vehicle_count >= 2
  AND (wp.wp_type IS NULL OR wp.wp_type = 'product')
GROUP BY
    w.w_warehouse_name,
    sm.sm_carrier,
    CASE WHEN sm.sm_carrier = 'FEDEX' THEN 'FedEx' ELSE 'Other' END,
    hd.hd_buy_potential,
    sa.total_ext_tax,
    sa.total_net_profit,
    sa.cnt_sales
ORDER BY sa.total_net_profit DESC
LIMIT 100
