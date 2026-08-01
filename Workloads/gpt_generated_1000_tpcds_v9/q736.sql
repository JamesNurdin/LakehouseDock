WITH base AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_item_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_return_amt_inc_tax,
        cr.cr_return_ship_cost,
        cr.cr_fee,
        cr.cr_refunded_cash,
        cr.cr_reversed_charge,
        cr.cr_store_credit,
        cr.cr_net_loss,
        cr.cr_order_number,
        i.i_item_id,
        i.i_product_name,
        i.i_current_price,
        i.i_brand,
        i.i_category,
        cc.cc_name AS call_center_name,
        cc.cc_state AS call_center_state,
        cp.cp_department,
        sm.sm_type AS ship_mode_type,
        wh.w_warehouse_name,
        wh.w_state AS warehouse_state,
        r_rc.r_reason_desc AS catalog_return_reason,
        sr.sr_return_quantity AS store_return_qty,
        sr.sr_return_amt AS store_return_amt,
        sr.sr_net_loss AS store_net_loss,
        r_sr.r_reason_desc AS store_return_reason,
        inv.inv_quantity_on_hand,
        inv.inv_date_sk,
        inv_wh.w_warehouse_name AS inv_warehouse_name,
        inv_wh.w_state AS inv_warehouse_state,
        wr.wr_return_quantity AS web_return_qty,
        wr.wr_return_amt AS web_return_amt,
        wr.wr_net_loss AS web_net_loss,
        r_wr.r_reason_desc AS web_return_reason,
        wp.wp_url,
        wp.wp_type
    FROM
        catalog_returns cr
        JOIN item i ON cr.cr_item_sk = i.i_item_sk
        JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
        JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse wh ON cr.cr_warehouse_sk = wh.w_warehouse_sk
        JOIN reason r_rc ON cr.cr_reason_sk = r_rc.r_reason_sk
        LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
        LEFT JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
        LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
        LEFT JOIN warehouse inv_wh ON inv.inv_warehouse_sk = inv_wh.w_warehouse_sk
        LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
        LEFT JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
        LEFT JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
    WHERE
        cr.cr_returned_date_sk BETWEEN 2450941 AND 2451081
        AND cr.cr_return_amount > 100.00
        AND i.i_current_price BETWEEN 10.00 AND 200.00
        AND sm.sm_type IN ('AIR', 'RAIL')
        AND cc.cc_state = 'CA'
        AND wh.w_state = 'TX'
        AND EXISTS (
            SELECT 1
            FROM reason r2
            WHERE r2.r_reason_desc = r_rc.r_reason_desc
              AND r2.r_reason_id LIKE 'R%'
        )
)
SELECT
    base.i_item_id,
    base.i_product_name,
    SUM(base.cr_return_amount) AS total_catalog_return_amount,
    COUNT(DISTINCT base.cr_order_number) AS catalog_return_orders,
    SUM(base.store_return_amt) AS total_store_return_amount,
    SUM(base.web_return_amt) AS total_web_return_amount,
    AVG(base.i_current_price) AS avg_current_price,
    SUM(base.inv_quantity_on_hand) AS total_inventory_on_hand
FROM
    base
GROUP BY
    base.i_item_id,
    base.i_product_name
HAVING
    SUM(base.cr_return_amount) > 5000
ORDER BY
    total_catalog_return_amount DESC
LIMIT 100
