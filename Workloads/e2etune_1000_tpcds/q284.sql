WITH high_value_customers AS (
    SELECT cd_demo_sk
    FROM customer_demographics
    WHERE cd_purchase_estimate >= 5000
      AND cd_education_status = 'College'
      AND cd_credit_rating = 'Excellent'
),
ws_agg AS (
    SELECT ws.ws_warehouse_sk,
           ws.ws_ship_mode_sk,
           SUM(ws.ws_net_profit) AS total_net_profit,
           SUM(ws.ws_net_paid) AS total_net_paid,
           SUM(ws.ws_ext_discount_amt) AS total_discount,
           COUNT(*) AS order_cnt
    FROM web_sales ws
    JOIN high_value_customers hvc ON ws.ws_bill_cdemo_sk = hvc.cd_demo_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450815 AND 2451088
    GROUP BY ws.ws_warehouse_sk, ws.ws_ship_mode_sk
),
inv_agg AS (
    SELECT inv.inv_warehouse_sk,
           AVG(inv.inv_quantity_on_hand) AS avg_qty_on_hand
    FROM inventory inv
    GROUP BY inv.inv_warehouse_sk
)
SELECT w.w_city,
       w.w_state,
       w.w_warehouse_name,
       sm.sm_type AS shipping_mode,
       ws_agg.total_net_profit,
       ws_agg.total_net_paid,
       ws_agg.total_discount,
       ws_agg.order_cnt,
       inv_agg.avg_qty_on_hand,
       RANK() OVER (PARTITION BY w.w_state ORDER BY ws_agg.total_net_profit DESC) AS profit_rank_state
FROM ws_agg
JOIN warehouse w ON ws_agg.ws_warehouse_sk = w.w_warehouse_sk
JOIN ship_mode sm ON ws_agg.ws_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN inv_agg ON ws_agg.ws_warehouse_sk = inv_agg.inv_warehouse_sk
WHERE ws_agg.total_net_profit > 100000
ORDER BY ws_agg.total_net_profit DESC
LIMIT 20
