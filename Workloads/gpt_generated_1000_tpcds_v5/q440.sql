WITH joined_data AS (
    SELECT
        w.w_warehouse_id,
        w.w_city,
        w.w_state,
        cc.cc_name,
        sm.sm_type,
        hd_ret.hd_buy_potential AS ret_buy_potential,
        hd_ws.hd_buy_potential AS ws_buy_potential,
        inv.inv_quantity_on_hand,
        cr.cr_return_amount,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_quantity,
        ws.ws_sold_date_sk
    FROM catalog_returns cr
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN inventory inv
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN household_demographics hd_ret
        ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
    JOIN web_sales ws
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
        AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN household_demographics hd_ws
        ON ws.ws_bill_hdemo_sk = hd_ws.hd_demo_sk
    WHERE cc.cc_state = 'CA'
      AND w.w_state = 'CA'
      AND sm.sm_type = 'AIR'
      AND hd_ret.hd_buy_potential = '>10000'
      AND inv.inv_quantity_on_hand > 500
      AND cr.cr_return_amount > 1000
      AND ws.ws_net_profit > 0
),
agg AS (
    SELECT
        w_warehouse_id,
        w_city,
        sm_type,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(cr_return_amount) AS total_returns,
        AVG(ws_net_profit) AS avg_profit,
        SUM(inv_quantity_on_hand) AS total_inventory
    FROM joined_data
    GROUP BY w_warehouse_id, w_city, sm_type
)
SELECT
    w_warehouse_id,
    w_city,
    sm_type,
    total_sales,
    total_returns,
    avg_profit,
    total_inventory,
    RANK() OVER (PARTITION BY sm_type ORDER BY total_sales DESC) AS sales_rank
FROM agg
ORDER BY total_sales DESC
LIMIT 100
