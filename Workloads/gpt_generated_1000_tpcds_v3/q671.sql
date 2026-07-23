SELECT
    s.s_store_name,
    s.s_state,
    p.p_promo_name,
    t.t_hour,
    cp.cp_department,
    w.w_state,
    SUM(ss.ss_ext_sales_price) AS total_store_sales,
    SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
    SUM(ws.ws_ext_sales_price) AS total_web_sales,
    SUM(wr.wr_return_amt) AS total_returns,
    SUM(ss.ss_net_profit) + SUM(cs.cs_net_profit) + SUM(ws.ws_net_profit) - SUM(wr.wr_net_loss) AS net_profit
FROM
    tpcds.time_dim t
    JOIN tpcds.store_sales ss ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN tpcds.store s ON ss.ss_store_sk = s.s_store_sk
    JOIN tpcds.promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN tpcds.customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN tpcds.customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.catalog_sales cs ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN tpcds.catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.inventory i ON i.inv_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.web_sales ws ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN tpcds.web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN tpcds.web_returns wr ON wr.wr_order_number = ws.ws_order_number
WHERE
    t.t_hour = 12
    AND s.s_state = 'CA'
    AND p.p_discount_active = 'Y'
    AND c.c_birth_month = 5
    AND w.w_street_type = 'Ave'
    AND i.inv_quantity_on_hand > 100
GROUP BY
    s.s_store_name,
    s.s_state,
    p.p_promo_name,
    t.t_hour,
    cp.cp_department,
    w.w_state
ORDER BY
    total_store_sales DESC
LIMIT 100
