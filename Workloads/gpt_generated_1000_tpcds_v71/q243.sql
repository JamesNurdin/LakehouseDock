WITH base AS (
    SELECT
        i.i_category,
        s.s_state,
        td.t_shift,
        ss.ss_net_paid               AS sales_amount,
        sr.sr_net_loss               AS store_return_loss,
        cr.cr_net_loss               AS catalog_return_loss,
        ws.ws_net_paid               AS web_sales_amount,
        wr.wr_net_loss               AS web_return_loss,
        inv.inv_quantity_on_hand
    FROM            tpcds.time_dim td
    JOIN            tpcds.store_sales ss
        ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN            tpcds.store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN            tpcds.item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN            tpcds.customer_address ca_ss
        ON ss.ss_addr_sk = ca_ss.ca_address_sk
    JOIN            tpcds.store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_return_time_sk = td.t_time_sk
    JOIN            tpcds.customer_address ca_sr
        ON sr.sr_addr_sk = ca_sr.ca_address_sk
    JOIN            tpcds.catalog_returns cr
        ON cr.cr_returned_time_sk = td.t_time_sk
        AND cr.cr_item_sk = i.i_item_sk
    JOIN            tpcds.ship_mode sm_cr
        ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
    JOIN            tpcds.warehouse w_cr
        ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
    JOIN            tpcds.customer_address ca_cr_refund
        ON cr.cr_refunded_addr_sk = ca_cr_refund.ca_address_sk
    JOIN            tpcds.customer_address ca_cr_returning
        ON cr.cr_returning_addr_sk = ca_cr_returning.ca_address_sk
    JOIN            tpcds.web_sales ws
        ON ws.ws_sold_time_sk = td.t_time_sk
        AND ws.ws_item_sk = i.i_item_sk
    JOIN            tpcds.ship_mode sm_ws
        ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    JOIN            tpcds.warehouse w_ws
        ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
    JOIN            tpcds.web_page wp_ws
        ON ws.ws_web_page_sk = wp_ws.wp_web_page_sk
    JOIN            tpcds.web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN            tpcds.customer_address ca_ws_bill
        ON ws.ws_bill_addr_sk = ca_ws_bill.ca_address_sk
    JOIN            tpcds.customer_address ca_ws_ship
        ON ws.ws_ship_addr_sk = ca_ws_ship.ca_address_sk
    JOIN            tpcds.web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_returned_time_sk = td.t_time_sk
        AND wr.wr_item_sk = i.i_item_sk
    JOIN            tpcds.customer_address ca_wr_refund
        ON wr.wr_refunded_addr_sk = ca_wr_refund.ca_address_sk
    JOIN            tpcds.customer_address ca_wr_returning
        ON wr.wr_returning_addr_sk = ca_wr_returning.ca_address_sk
    JOIN            tpcds.web_page wp_wr
        ON wr.wr_web_page_sk = wp_wr.wp_web_page_sk
    JOIN            tpcds.inventory inv
        ON inv.inv_item_sk = i.i_item_sk
    JOIN            tpcds.warehouse w_inv
        ON inv.inv_warehouse_sk = w_inv.w_warehouse_sk
    WHERE td.t_shift IN ('first', 'second')
      AND wsite.web_manager = 'Jimmy Pope'
      AND inv.inv_quantity_on_hand > 100
)
SELECT
    i_category,
    s_state,
    GROUPING(i_category) AS g_category,
    GROUPING(s_state)    AS g_state,
    SUM(sales_amount)        AS total_sales,
    SUM(store_return_loss)   AS total_store_return_loss,
    SUM(catalog_return_loss) AS total_catalog_return_loss,
    SUM(web_sales_amount)    AS total_web_sales,
    SUM(web_return_loss)     AS total_web_return_loss
FROM base
GROUP BY ROLLUP(i_category, s_state)
HAVING SUM(sales_amount) > 0
ORDER BY i_category NULLS LAST, s_state NULLS LAST
LIMIT 100
