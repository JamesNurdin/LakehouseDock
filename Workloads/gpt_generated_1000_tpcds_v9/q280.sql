WITH sales_agg AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_name,
        i.i_category,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        SUM(ss.ss_net_profit) AS store_net_profit,
        COALESCE(SUM(cr.cr_net_loss), 0) AS catalog_net_loss,
        COALESCE(SUM(sr.sr_net_loss), 0) AS store_net_loss,
        COALESCE(SUM(wr.wr_net_loss), 0) AS web_net_loss,
        COALESCE(SUM(inv.inv_quantity_on_hand), 0) AS total_inventory_qty
    FROM
        catalog_sales cs
        INNER JOIN date_dim d_cs_sold
            ON cs.cs_sold_date_sk = d_cs_sold.d_date_sk
        INNER JOIN call_center cc
            ON cs.cs_call_center_sk = cc.cc_call_center_sk
        INNER JOIN ship_mode sm
            ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        INNER JOIN warehouse w
            ON cs.cs_warehouse_sk = w.w_warehouse_sk
        INNER JOIN item i
            ON cs.cs_item_sk = i.i_item_sk
        INNER JOIN customer c
            ON cs.cs_bill_customer_sk = c.c_customer_sk
        LEFT JOIN store_sales ss
            ON ss.ss_item_sk = i.i_item_sk
            AND ss.ss_customer_sk = c.c_customer_sk
        LEFT JOIN date_dim d_ss
            ON ss.ss_sold_date_sk = d_ss.d_date_sk
        LEFT JOIN store_returns sr
            ON sr.sr_ticket_number = ss.ss_ticket_number
            AND sr.sr_item_sk = i.i_item_sk
            AND sr.sr_customer_sk = c.c_customer_sk
        LEFT JOIN date_dim d_sr
            ON sr.sr_returned_date_sk = d_sr.d_date_sk
        LEFT JOIN reason r_sr
            ON sr.sr_reason_sk = r_sr.r_reason_sk
        LEFT JOIN catalog_returns cr
            ON cr.cr_order_number = cs.cs_order_number
            AND cr.cr_item_sk = i.i_item_sk
            AND cr.cr_call_center_sk = cc.cc_call_center_sk
            AND cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
            AND cr.cr_warehouse_sk = w.w_warehouse_sk
        LEFT JOIN date_dim d_cr
            ON cr.cr_returned_date_sk = d_cr.d_date_sk
        LEFT JOIN reason r_cr
            ON cr.cr_reason_sk = r_cr.r_reason_sk
        LEFT JOIN web_returns wr
            ON wr.wr_item_sk = i.i_item_sk
            AND wr.wr_refunded_customer_sk = c.c_customer_sk
        LEFT JOIN date_dim d_wr
            ON wr.wr_returned_date_sk = d_wr.d_date_sk
        LEFT JOIN reason r_wr
            ON wr.wr_reason_sk = r_wr.r_reason_sk
        LEFT JOIN inventory inv
            ON inv.inv_item_sk = i.i_item_sk
            AND inv.inv_warehouse_sk = w.w_warehouse_sk
        LEFT JOIN date_dim d_inv
            ON inv.inv_date_sk = d_inv.d_date_sk
        LEFT JOIN web_site ws
            ON ws.web_manager = 'Marshall Conner'
        LEFT JOIN date_dim d_ws_open
            ON ws.web_open_date_sk = d_ws_open.d_date_sk
        LEFT JOIN date_dim d_ws_close
            ON ws.web_close_date_sk = d_ws_close.d_date_sk
    WHERE
        d_cs_sold.d_year = 2001
        AND i.i_category = 'Electronics'
        AND sm.sm_code = 'AIR'
        AND cc.cc_company_name = 'cally'
        AND w.w_state = 'CA'
        AND ws.web_manager = 'Marshall Conner'
        AND d_ws_open.d_year = 2001
        AND NOT EXISTS (
            SELECT 1 FROM web_returns wr2
            WHERE wr2.wr_item_sk = i.i_item_sk
        )
    GROUP BY
        cc.cc_call_center_id,
        cc.cc_name,
        i.i_category
)
SELECT
    ca.cc_call_center_id,
    ca.cc_name,
    SUM(ca.total_inventory_qty) AS total_inventory_qty,
    SUM(ca.catalog_net_profit + ca.store_net_profit - ca.catalog_net_loss - ca.store_net_loss - ca.web_net_loss) AS total_net_profit
FROM
    sales_agg ca
GROUP BY
    ca.cc_call_center_id,
    ca.cc_name
HAVING
    SUM(ca.catalog_net_profit + ca.store_net_profit - ca.catalog_net_loss - ca.store_net_loss - ca.web_net_loss) > 10000
ORDER BY
    total_net_profit DESC
LIMIT 100
