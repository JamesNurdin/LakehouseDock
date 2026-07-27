WITH ss_agg AS (
    SELECT
        ss_customer_sk,
        ss_sold_time_sk,
        SUM(ss_net_profit) AS ss_total_profit,
        COUNT(*) AS ss_txn_cnt
    FROM store_sales
    WHERE ss_net_profit > 0
    GROUP BY ss_customer_sk, ss_sold_time_sk
)
SELECT
    w.w_state,
    sm.sm_type,
    SUM(ss_agg.ss_total_profit) AS total_store_profit,
    SUM(cr.cr_net_loss) AS total_return_loss,
    COUNT(DISTINCT ss_agg.ss_customer_sk) AS distinct_customers,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_return_orders
FROM ss_agg
JOIN customer c ON ss_agg.ss_customer_sk = c.c_customer_sk
JOIN time_dim t ON ss_agg.ss_sold_time_sk = t.t_time_sk
JOIN catalog_returns cr ON t.t_time_sk = cr.cr_returned_time_sk
JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN inventory inv ON w.w_warehouse_sk = inv.inv_warehouse_sk
    AND inv.inv_quantity_on_hand > (
        SELECT AVG(inv2.inv_quantity_on_hand) FROM inventory inv2
    )
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
JOIN web_sales ws ON t.t_time_sk = ws.ws_sold_time_sk
JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
JOIN customer c_bill ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
JOIN customer_demographics cd_cur ON c.c_current_cdemo_sk = cd_cur.cd_demo_sk
JOIN customer_demographics cd_refunded ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
JOIN customer c_refunded ON cr.cr_refunded_customer_sk = c_refunded.c_customer_sk
JOIN customer c_returning ON cr.cr_returning_customer_sk = c_returning.c_customer_sk
GROUP BY w.w_state, sm.sm_type
ORDER BY total_store_profit DESC
LIMIT 100
