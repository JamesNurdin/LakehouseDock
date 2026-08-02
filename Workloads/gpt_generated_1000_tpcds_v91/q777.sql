SELECT
    COALESCE(i_cs.i_category, i_cr.i_category) AS category,
    COALESCE(i_cs.i_brand, i_cr.i_brand) AS brand,
    COALESCE(w_cs.w_state, w_cr.w_state) AS warehouse_state,
    COALESCE(sm_cs.sm_carrier, sm_cr.sm_carrier, sm_ws.sm_carrier) AS carrier,
    COALESCE(t_cs.t_hour, t_cr.t_hour, t_ws.t_hour) AS hour,
    SUM(COALESCE(cs.cs_net_paid, 0)) AS total_sales,
    SUM(COALESCE(cr.cr_return_amount, 0)) AS total_returns,
    SUM(COALESCE(ws.ws_net_paid, 0)) AS total_web_sales,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    AVG(COALESCE(ws.ws_net_paid, 0)) AS avg_web_paid,
    MIN(COALESCE(inv_cs.inv_quantity_on_hand, inv_cr.inv_quantity_on_hand)) AS min_inventory_qty,
    MAX(COALESCE(inv_cs.inv_quantity_on_hand, inv_cr.inv_quantity_on_hand)) AS max_inventory_qty
FROM catalog_sales cs
FULL OUTER JOIN catalog_returns cr
    ON cs.cs_order_number = cr.cr_order_number
LEFT JOIN item i_cs
    ON cs.cs_item_sk = i_cs.i_item_sk
LEFT JOIN item i_cr
    ON cr.cr_item_sk = i_cr.i_item_sk
LEFT JOIN inventory inv_cs
    ON inv_cs.inv_item_sk = i_cs.i_item_sk
LEFT JOIN inventory inv_cr
    ON inv_cr.inv_item_sk = i_cr.i_item_sk
LEFT JOIN warehouse w_cs
    ON cs.cs_warehouse_sk = w_cs.w_warehouse_sk
LEFT JOIN warehouse w_cr
    ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
LEFT JOIN warehouse w_inv_cs
    ON inv_cs.inv_warehouse_sk = w_inv_cs.w_warehouse_sk
LEFT JOIN warehouse w_inv_cr
    ON inv_cr.inv_warehouse_sk = w_inv_cr.w_warehouse_sk
LEFT JOIN ship_mode sm_cs
    ON cs.cs_ship_mode_sk = sm_cs.sm_ship_mode_sk
LEFT JOIN ship_mode sm_cr
    ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
LEFT JOIN reason r_cr
    ON cr.cr_reason_sk = r_cr.r_reason_sk
LEFT JOIN time_dim t_cs
    ON cs.cs_sold_time_sk = t_cs.t_time_sk
LEFT JOIN time_dim t_cr
    ON cr.cr_returned_time_sk = t_cr.t_time_sk
LEFT JOIN customer_demographics cd_cs_bill
    ON cs.cs_bill_cdemo_sk = cd_cs_bill.cd_demo_sk
LEFT JOIN customer_demographics cd_cs_ship
    ON cs.cs_ship_cdemo_sk = cd_cs_ship.cd_demo_sk
LEFT JOIN customer_demographics cd_cr_refunded
    ON cr.cr_refunded_cdemo_sk = cd_cr_refunded.cd_demo_sk
LEFT JOIN customer_demographics cd_cr_returning
    ON cr.cr_returning_cdemo_sk = cd_cr_returning.cd_demo_sk
LEFT JOIN web_sales ws
    ON ws.ws_item_sk = i_cs.i_item_sk
LEFT JOIN time_dim t_ws
    ON ws.ws_sold_time_sk = t_ws.t_time_sk
LEFT JOIN ship_mode sm_ws
    ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
LEFT JOIN warehouse w_ws
    ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
LEFT JOIN web_page wp_ws
    ON ws.ws_web_page_sk = wp_ws.wp_web_page_sk
LEFT JOIN customer_demographics cd_ws_bill
    ON ws.ws_bill_cdemo_sk = cd_ws_bill.cd_demo_sk
LEFT JOIN customer_demographics cd_ws_ship
    ON ws.ws_ship_cdemo_sk = cd_ws_ship.cd_demo_sk
WHERE
    i_cs.i_brand = 'Brand#23'
    AND w_cs.w_state = 'CA'
    AND sm_cs.sm_carrier = 'UPS'
    AND r_cr.r_reason_desc = 'Damaged'
    AND inv_cs.inv_quantity_on_hand > 500
    AND t_cs.t_hour BETWEEN 9 AND 17
    AND EXISTS (
        SELECT 1
        FROM store_sales ss
        JOIN time_dim t_ss ON ss.ss_sold_time_sk = t_ss.t_time_sk
        JOIN item i_ss ON ss.ss_item_sk = i_ss.i_item_sk
        WHERE ss.ss_item_sk = cs.cs_item_sk
          AND i_ss.i_category = 'Electronics'
          AND t_ss.t_hour BETWEEN 9 AND 12
          AND ss.ss_quantity > 5
    )
GROUP BY
    COALESCE(i_cs.i_category, i_cr.i_category),
    COALESCE(i_cs.i_brand, i_cr.i_brand),
    COALESCE(w_cs.w_state, w_cr.w_state),
    COALESCE(sm_cs.sm_carrier, sm_cr.sm_carrier, sm_ws.sm_carrier),
    COALESCE(t_cs.t_hour, t_cr.t_hour, t_ws.t_hour)
LIMIT 100
