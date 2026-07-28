/*
Goal: Produce a year‑and‑store‑state level summary that combines sales, returns, catalog returns, web sales and inventory information across the entire TPC‑DS dataset. The query joins all selected tables (using each of the allowed join rules), re‑uses the DATE_DIM and REASON tables under different aliases, applies a CASE expression to isolate positive loss amounts, and limits the output to the top 100 rows by total store sales.
*/
SELECT
    d.d_year,
    s.s_state,
    COUNT(DISTINCT ss.ss_ticket_number) AS orders,
    SUM(ss.ss_net_paid) AS total_store_sales,
    SUM(CASE WHEN sr.sr_net_loss > 0 THEN sr.sr_net_loss ELSE 0 END) AS total_store_returns,
    SUM(CASE WHEN cr.cr_net_loss > 0 THEN cr.cr_net_loss ELSE 0 END) AS total_catalog_returns,
    SUM(ws.ws_net_paid) AS total_web_sales,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand,
    SUM(CASE WHEN sm.sm_type = 'AIR' THEN 1 ELSE 0 END) AS air_ship_mode_count
FROM
    store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    /* Store returns – uses the same date, time, customer and store dimensions already joined */
    JOIN store_returns sr
        ON sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_returned_date_sk = d.d_date_sk
        AND sr.sr_return_time_sk = t.t_time_sk
    JOIN reason r_ret ON sr.sr_reason_sk = r_ret.r_reason_sk
    /* Catalog returns – also re‑uses the previously joined dimensions */
    JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
        AND cr.cr_returned_time_sk = t.t_time_sk
        AND cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
        AND cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
    /* Web sales – joins to the same date, time, ship mode and warehouse dimensions */
    JOIN web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_sold_time_sk = t.t_time_sk
        AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        AND ws.ws_warehouse_sk = w.w_warehouse_sk
        AND ws.ws_bill_cdemo_sk = cd.cd_demo_sk
        AND ws.ws_bill_addr_sk = ca.ca_address_sk
    /* Second alias of DATE_DIM for the ship date of web sales */
    JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
    /* Inventory – joins to the same date and warehouse dimensions */
    JOIN inventory inv
        ON inv.inv_date_sk = d.d_date_sk
        AND inv.inv_warehouse_sk = w.w_warehouse_sk
GROUP BY
    d.d_year,
    s.s_state
ORDER BY
    total_store_sales DESC
LIMIT 100
