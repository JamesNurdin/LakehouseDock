WITH raw_data AS (
    SELECT
        s.s_state AS store_state,
        cc.cc_state AS call_center_state,
        w.w_state AS warehouse_state,
        t.t_hour AS sales_hour,
        sm.sm_type AS ship_mode_type,
        wp.wp_type AS web_page_type,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(sr.sr_return_amt) AS total_store_return_amount,
        SUM(cr.cr_return_amount) AS total_catalog_return_amount,
        SUM(wr.wr_return_amt) AS total_web_return_amount,
        MAX(inv_agg.total_qty) AS total_inventory_qty,
        COUNT(DISTINCT ws.ws_order_number) AS num_sales_orders,
        COUNT(DISTINCT sr.sr_ticket_number) AS num_store_returns,
        COUNT(DISTINCT cr.cr_order_number) AS num_catalog_returns,
        COUNT(DISTINCT wr.wr_order_number) AS num_web_returns,
        MAX(ws.ws_order_number) AS max_ws_order_number
    FROM time_dim t
    JOIN store_returns sr
        ON sr.sr_return_time_sk = t.t_time_sk
    LEFT JOIN store s
        ON s.s_store_sk = sr.sr_store_sk
    LEFT JOIN customer_demographics cd_sr
        ON cd_sr.cd_demo_sk = sr.sr_cdemo_sk
    LEFT JOIN household_demographics hd_sr
        ON hd_sr.hd_demo_sk = sr.sr_hdemo_sk
    LEFT JOIN customer_address ca_sr
        ON ca_sr.ca_address_sk = sr.sr_addr_sk
    JOIN catalog_returns cr
        ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN call_center cc
        ON cc.cc_call_center_sk = cr.cr_call_center_sk
    JOIN ship_mode sm
        ON sm.sm_ship_mode_sk = cr.cr_ship_mode_sk
    JOIN warehouse w
        ON w.w_warehouse_sk = cr.cr_warehouse_sk
    LEFT JOIN customer_demographics cd_cr_refund
        ON cd_cr_refund.cd_demo_sk = cr.cr_refunded_cdemo_sk
    LEFT JOIN household_demographics hd_cr_refund
        ON hd_cr_refund.hd_demo_sk = cr.cr_refunded_hdemo_sk
    LEFT JOIN customer_address ca_cr_refund
        ON ca_cr_refund.ca_address_sk = cr.cr_refunded_addr_sk
    JOIN web_sales ws
        ON ws.ws_sold_time_sk = t.t_time_sk
        AND ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp
        ON wp.wp_web_page_sk = ws.ws_web_page_sk
    JOIN ship_mode sm_ws
        ON sm_ws.sm_ship_mode_sk = ws.ws_ship_mode_sk
    LEFT JOIN customer_demographics cd_ws_bill
        ON cd_ws_bill.cd_demo_sk = ws.ws_bill_cdemo_sk
    LEFT JOIN household_demographics hd_ws_bill
        ON hd_ws_bill.hd_demo_sk = ws.ws_bill_hdemo_sk
    LEFT JOIN customer_address ca_ws_bill
        ON ca_ws_bill.ca_address_sk = ws.ws_bill_addr_sk
    LEFT JOIN customer_demographics cd_ws_ship
        ON cd_ws_ship.cd_demo_sk = ws.ws_ship_cdemo_sk
    LEFT JOIN household_demographics hd_ws_ship
        ON hd_ws_ship.hd_demo_sk = ws.ws_ship_hdemo_sk
    LEFT JOIN customer_address ca_ws_ship
        ON ca_ws_ship.ca_address_sk = ws.ws_ship_addr_sk
    LEFT JOIN web_returns wr
        ON wr.wr_returned_time_sk = t.t_time_sk
        AND wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
        AND wr.wr_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN customer_demographics cd_wr_refund
        ON cd_wr_refund.cd_demo_sk = wr.wr_refunded_cdemo_sk
    LEFT JOIN household_demographics hd_wr_refund
        ON hd_wr_refund.hd_demo_sk = wr.wr_refunded_hdemo_sk
    LEFT JOIN customer_address ca_wr_refund
        ON ca_wr_refund.ca_address_sk = wr.wr_refunded_addr_sk
    CROSS JOIN LATERAL (
        SELECT SUM(i.inv_quantity_on_hand) AS total_qty
        FROM inventory i
        WHERE i.inv_warehouse_sk = w.w_warehouse_sk
    ) AS inv_agg
    WHERE
        sr.sr_return_tax > 10
        AND cr.cr_return_amount > 100
        AND ws.ws_quantity > 2
        AND w.w_warehouse_sq_ft > 5000
        AND cc.cc_gmt_offset BETWEEN -5 AND 5
    GROUP BY
        s.s_state,
        cc.cc_state,
        w.w_state,
        t.t_hour,
        sm.sm_type,
        wp.wp_type
)
SELECT
    rd.store_state,
    rd.call_center_state,
    rd.warehouse_state,
    rd.sales_hour,
    rd.ship_mode_type,
    rd.web_page_type,
    rd.total_sales,
    rd.total_quantity,
    rd.total_store_return_amount,
    rd.total_catalog_return_amount,
    rd.total_web_return_amount,
    rd.total_inventory_qty,
    rd.num_sales_orders,
    rd.num_store_returns,
    rd.num_catalog_returns,
    rd.num_web_returns,
    rd.max_ws_order_number,
    rd.total_sales / NULLIF(rd.num_sales_orders, 0) AS avg_sales_per_order
FROM raw_data rd
WHERE NOT EXISTS (
    SELECT 1 FROM catalog_returns cr2
    WHERE cr2.cr_order_number = rd.max_ws_order_number
)
ORDER BY rd.total_sales DESC
OFFSET 0
LIMIT 100
