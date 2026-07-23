WITH base AS (
    SELECT
        s.s_store_name,
        i.i_category,
        td.t_hour,
        r.r_reason_desc,
        sm.sm_type,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        SUM(sr.sr_return_amt) AS total_store_returns,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(wr.wr_return_amt) AS total_web_returns,
        SUM(inv.inv_quantity_on_hand) AS total_inventory_qty,
        COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
        SUM(CASE WHEN ss.ss_sales_price > 100 THEN ss.ss_ext_sales_price ELSE 0 END) AS high_value_sales,
        SUM(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_customer_sk = c.c_customer_sk
        AND sr.sr_store_sk = s.s_store_sk
        AND sr.sr_addr_sk = ca.ca_address_sk
        AND sr.sr_return_time_sk = td.t_time_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
        AND cr.cr_returned_time_sk = td.t_time_sk
        AND cr.cr_refunded_customer_sk = c.c_customer_sk
        AND cr.cr_refunded_addr_sk = ca.ca_address_sk
        AND cr.cr_reason_sk = r.r_reason_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN web_sales ws ON ws.ws_sold_time_sk = td.t_time_sk
        AND ws.ws_item_sk = i.i_item_sk
        AND ws.ws_bill_customer_sk = c.c_customer_sk
        AND ws.ws_bill_addr_sk = ca.ca_address_sk
        AND ws.ws_ship_customer_sk = c.c_customer_sk
        AND ws.ws_ship_addr_sk = ca.ca_address_sk
        AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        AND ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_returns wr ON wr.wr_returned_time_sk = td.t_time_sk
        AND wr.wr_item_sk = i.i_item_sk
        AND wr.wr_order_number = ws.ws_order_number
        AND wr.wr_refunded_customer_sk = c.c_customer_sk
        AND wr.wr_refunded_addr_sk = ca.ca_address_sk
        AND wr.wr_reason_sk = r.r_reason_sk
    WHERE td.t_hour BETWEEN 9 AND 17
        AND i.i_brand = 'Brand#12'
        AND s.s_state = 'CA'
        AND sm.sm_type = 'AIR'
        AND inv.inv_quantity_on_hand > 100
        AND cp.cp_type = 'PROMO'
        AND r.r_reason_desc = 'Damaged'
        AND c.c_preferred_cust_flag = 'Y'
        AND ws.ws_quantity > 2
        AND ss.ss_quantity > 5
        AND EXISTS (
            SELECT 1
            FROM call_center cc
            WHERE cc.cc_call_center_sk = cr.cr_call_center_sk
              AND cc.cc_state = 'CA'
        )
    GROUP BY
        s.s_store_name,
        i.i_category,
        td.t_hour,
        r.r_reason_desc,
        sm.sm_type
    HAVING SUM(ss.ss_ext_sales_price) > 10000
       AND COUNT(DISTINCT c.c_customer_sk) >= 5
)
SELECT
    s_store_name,
    i_category,
    t_hour,
    r_reason_desc,
    sm_type,
    total_store_sales,
    total_store_returns,
    total_web_sales,
    total_web_returns,
    total_inventory_qty,
    unique_customers,
    high_value_sales,
    total_quantity,
    CASE WHEN total_quantity >= 10 THEN 'Bulk' ELSE 'Single' END AS order_category
FROM base
ORDER BY total_store_sales DESC
LIMIT 100
