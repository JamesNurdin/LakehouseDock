SELECT
    s.s_store_id,
    wp.wp_type,
    d.d_month_seq,
    hd.hd_buy_potential,
    sm.sm_ship_mode_id,
    SUM(cs.cs_net_profit) AS total_catalog_net_profit,
    SUM(ws.ws_net_profit) AS total_web_net_profit,
    SUM(sr.sr_net_loss) AS total_store_return_loss,
    SUM(wr.wr_net_loss) AS total_web_return_loss,
    SUM(i.inv_quantity_on_hand) AS total_inventory_on_hand,
    AVG(cs.cs_ext_sales_price) AS avg_catalog_sales_price,
    MIN(cs.cs_ext_sales_price) AS min_catalog_sales_price,
    MAX(cs.cs_ext_sales_price) AS max_catalog_sales_price,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_catalog_orders,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_web_orders,
    SUM(CASE WHEN cs.cs_ext_sales_price > 5000 THEN cs.cs_net_profit ELSE 0 END) AS high_value_catalog_profit
FROM
    date_dim d
    INNER JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
    INNER JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    INNER JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    INNER JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    INNER JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    INNER JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    INNER JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_bill_customer_sk = c.c_customer_sk
        AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
        AND ws.ws_bill_addr_sk = ca.ca_address_sk
        AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        AND ws.ws_warehouse_sk = w.w_warehouse_sk
    INNER JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
        AND ws.ws_web_page_sk = wp.wp_web_page_sk
    INNER JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    INNER JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
        AND sr.sr_customer_sk = c.c_customer_sk
        AND sr.sr_hdemo_sk = hd.hd_demo_sk
        AND sr.sr_addr_sk = ca.ca_address_sk
        AND sr.sr_store_sk = s.s_store_sk
    INNER JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_item_sk = ws.ws_item_sk
        AND wr.wr_order_number = ws.ws_order_number
        AND wr.wr_refunded_customer_sk = c.c_customer_sk
        AND wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
        AND wr.wr_refunded_addr_sk = ca.ca_address_sk
        AND wr.wr_web_page_sk = wp.wp_web_page_sk
    INNER JOIN inventory i ON i.inv_date_sk = d.d_date_sk
        AND i.inv_warehouse_sk = w.w_warehouse_sk
WHERE
    d.d_year = 2001
    AND d.d_holiday = 'Y'
    AND s.s_state = 'CA'
    AND sm.sm_type = 'AIR'
    AND w.w_state = 'TX'
    AND ca.ca_country = 'United States'
    AND cs.cs_ext_sales_price > 1000.00
    AND ws.ws_quantity >= 2
    AND i.inv_quantity_on_hand > 0
GROUP BY
    s.s_store_id,
    wp.wp_type,
    d.d_month_seq,
    hd.hd_buy_potential,
    sm.sm_ship_mode_id
LIMIT 100
