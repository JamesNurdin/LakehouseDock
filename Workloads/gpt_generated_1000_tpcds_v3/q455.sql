WITH
joined_data AS (
    SELECT
        i.i_category,
        i.i_brand,
        i.i_item_id,
        store_ss.s_state,
        store_ss.s_city,
        ws_site.web_name,
        sm.sm_type,
        w.w_country,
        ss.ss_ext_sales_price AS store_sales_amount,
        ss.ss_net_profit AS store_net_profit,
        ws.ws_ext_sales_price AS web_sales_amount,
        ws.ws_net_profit AS web_net_profit,
        sr.sr_return_amt_inc_tax AS store_return_amount,
        sr.sr_net_loss AS store_return_loss,
        wr.wr_return_amt_inc_tax AS web_return_amount,
        wr.wr_net_loss AS web_return_loss,
        inv_cur.inv_quantity_on_hand AS current_inventory_qty,
        inv_prev.inv_quantity_on_hand AS previous_inventory_qty
    FROM store_sales ss
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN customer cust_ss
        ON ss.ss_customer_sk = cust_ss.c_customer_sk
    JOIN store store_ss
        ON ss.ss_store_sk = store_ss.s_store_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
           AND sr.sr_item_sk = i.i_item_sk
    LEFT JOIN customer sr_cust
        ON sr.sr_customer_sk = sr_cust.c_customer_sk
    LEFT JOIN store store_sr
        ON sr.sr_store_sk = store_sr.s_store_sk
    LEFT JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN web_site ws_site
        ON ws.ws_web_site_sk = ws_site.web_site_sk
    LEFT JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN customer ws_cust_bill
        ON ws.ws_bill_customer_sk = ws_cust_bill.c_customer_sk
    LEFT JOIN customer ws_cust_ship
        ON ws.ws_ship_customer_sk = ws_cust_ship.c_customer_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
           AND wr.wr_item_sk = i.i_item_sk
    LEFT JOIN customer wr_refund_cust
        ON wr.wr_refunded_customer_sk = wr_refund_cust.c_customer_sk
    LEFT JOIN customer wr_return_cust
        ON wr.wr_returning_customer_sk = wr_return_cust.c_customer_sk
    LEFT JOIN web_page wp_return
        ON wr.wr_web_page_sk = wp_return.wp_web_page_sk
    LEFT JOIN inventory inv_cur
        ON inv_cur.inv_item_sk = i.i_item_sk
           AND inv_cur.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN inventory inv_prev
        ON inv_prev.inv_item_sk = i.i_item_sk
           AND inv_prev.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN customer wp_cust
        ON wp.wp_customer_sk = wp_cust.c_customer_sk
    WHERE w.w_country = 'United States'
)
SELECT
    i_category,
    s_state,
    web_name,
    sm_type,
    SUM(store_sales_amount) AS total_store_sales,
    SUM(web_sales_amount) AS total_web_sales,
    SUM(store_return_amount) AS total_store_returns,
    SUM(web_return_amount) AS total_web_returns,
    SUM(store_net_profit) + SUM(web_net_profit) - SUM(store_return_loss) - SUM(web_return_loss) AS net_profit,
    AVG(current_inventory_qty) AS avg_current_inventory,
    AVG(previous_inventory_qty) AS avg_previous_inventory
FROM joined_data
GROUP BY i_category, s_state, web_name, sm_type
ORDER BY net_profit DESC
LIMIT 100
