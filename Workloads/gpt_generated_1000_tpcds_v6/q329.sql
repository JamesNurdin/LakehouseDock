WITH base_join AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit,
        i.i_item_id,
        i.i_category,
        c.c_customer_id,
        cd.cd_gender,
        ca.ca_state,
        wp.wp_url,
        sm.sm_type,
        w.w_warehouse_name,
        w.w_city,
        r.r_reason_desc,
        cr.cr_return_amount,
        sr.sr_return_amt,
        wr.wr_return_amt,
        inv.inv_quantity_on_hand
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
    LEFT JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk AND sr.sr_customer_sk = c.c_customer_sk
    LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk AND wr.wr_returning_customer_sk = c.c_customer_sk
    LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE
        ws.ws_quantity > 2
        AND ws.ws_sales_price > 100
        AND i.i_category = 'Sports'
        AND ca.ca_state = 'CA'
        AND w.w_city = 'Miller'
)
SELECT
    i_category,
    ca_state,
    SUM(ws_net_profit) AS total_profit,
    AVG(inv_quantity_on_hand) AS avg_stock_on_hand,
    SUM(COALESCE(cr_return_amount, 0) + COALESCE(sr_return_amt, 0) + COALESCE(wr_return_amt, 0)) AS total_return_amount
FROM base_join
GROUP BY i_category, ca_state
HAVING SUM(ws_net_profit) > 1000
ORDER BY total_profit DESC
LIMIT 100
