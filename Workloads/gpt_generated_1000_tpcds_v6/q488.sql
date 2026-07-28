WITH base AS (
    SELECT
        d.d_date,
        i.i_category,
        sm.sm_carrier,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(cr.cr_return_amount) AS total_catalog_return,
        SUM(sr.sr_return_amt) AS total_store_return,
        SUM(wr.wr_return_amt) AS total_web_return,
        SUM(inv.inv_quantity_on_hand) AS total_inventory_qty,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
        AND cr.cr_item_sk = i.i_item_sk
        AND cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        AND cr.cr_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
        AND inv.inv_item_sk = i.i_item_sk
        AND inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_item_sk = i.i_item_sk
        AND wr.wr_order_number = ws.ws_order_number
    LEFT JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
        AND sr.sr_item_sk = i.i_item_sk
        AND sr.sr_store_sk = s.s_store_sk
    WHERE d.d_year = 2001
      AND sm.sm_carrier = 'AIRBORNE'
      AND wr.wr_refunded_cash > 100
    GROUP BY d.d_date, i.i_category, sm.sm_carrier
)
SELECT
    d_date,
    i_category,
    sm_carrier,
    total_sales,
    total_catalog_return,
    total_store_return,
    total_web_return,
    total_inventory_qty,
    order_cnt,
    ROW_NUMBER() OVER (PARTITION BY d_date ORDER BY total_sales DESC) AS sales_rank
FROM base
ORDER BY d_date, sales_rank
LIMIT 100
