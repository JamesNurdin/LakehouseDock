SELECT
    i.i_category AS item_category,
    w.w_state AS warehouse_state,
    t_sold.t_hour AS sale_hour,
    SUM(ws.ws_net_profit) AS total_web_net_profit,
    SUM(cr.cr_net_loss) AS total_catalog_net_loss,
    SUM(sr.sr_net_loss) AS total_store_net_loss,
    SUM(wr.wr_net_loss) AS total_web_return_net_loss,
    SUM(inv.inv_quantity_on_hand) AS total_quantity_on_hand,
    (SELECT AVG(i2.i_current_price) FROM item i2) AS avg_item_price_all_items
FROM
    web_sales ws
    INNER JOIN time_dim t_sold ON ws.ws_sold_time_sk = t_sold.t_time_sk
    INNER JOIN item i ON ws.ws_item_sk = i.i_item_sk
    INNER JOIN customer c_bill ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
    INNER JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    INNER JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    INNER JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    INNER JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    INNER JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
                               AND ws.ws_item_sk = wr.wr_item_sk
    LEFT JOIN time_dim t_wr_return ON wr.wr_returned_time_sk = t_wr_return.t_time_sk
    LEFT JOIN customer c_wr_refunded ON wr.wr_refunded_customer_sk = c_wr_refunded.c_customer_sk
    LEFT JOIN customer_demographics cd_wr_refunded ON wr.wr_refunded_cdemo_sk = cd_wr_refunded.cd_demo_sk
    LEFT JOIN web_page wp_wr ON wr.wr_web_page_sk = wp_wr.wp_web_page_sk
    LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
    LEFT JOIN time_dim t_sr_return ON sr.sr_return_time_sk = t_sr_return.t_time_sk
    LEFT JOIN customer c_sr ON sr.sr_customer_sk = c_sr.c_customer_sk
    LEFT JOIN customer_demographics cd_sr ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
    LEFT JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
    LEFT JOIN time_dim t_cr_return ON cr.cr_returned_time_sk = t_cr_return.t_time_sk
    LEFT JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN ship_mode sm_cr ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
    LEFT JOIN warehouse w_cr ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
    LEFT JOIN customer c_cr_refunded ON cr.cr_refunded_customer_sk = c_cr_refunded.c_customer_sk
    LEFT JOIN customer_demographics cd_cr_refunded ON cr.cr_refunded_cdemo_sk = cd_cr_refunded.cd_demo_sk
    LEFT JOIN customer c_cr_returning ON cr.cr_returning_customer_sk = c_cr_returning.c_customer_sk
    LEFT JOIN customer_demographics cd_cr_returning ON cr.cr_returning_cdemo_sk = cd_cr_returning.cd_demo_sk
    LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
WHERE
    i.i_brand = 'Brand#12'
    AND w.w_state = 'CA'
    AND cd_bill.cd_gender = 'M'
    AND t_sold.t_hour = 14
    AND sm.sm_type = 'AIR'
    AND c_bill.c_birth_month = 5
GROUP BY
    i.i_category,
    w.w_state,
    t_sold.t_hour
ORDER BY
    total_web_net_profit DESC
LIMIT 100
