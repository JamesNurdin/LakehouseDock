SELECT
    d.d_year,
    s.s_store_name,
    w.w_warehouse_name,
    sm.sm_type,
    we.web_name,
    r.r_reason_desc,
    SUM(cs.cs_net_paid) AS total_catalog_sales,
    SUM(ws.ws_net_paid) AS total_web_sales,
    SUM(ss.ss_net_paid) AS total_store_sales,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_catalog_orders,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_web_orders,
    AVG(inv.inv_quantity_on_hand) AS avg_inventory_qty
FROM date_dim d
JOIN store_sales ss
    ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN inventory inv
    ON inv.inv_date_sk = d.d_date_sk
JOIN warehouse w
    ON inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN catalog_sales cs
    ON cs.cs_sold_date_sk = d.d_date_sk
   AND cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_sales ws
    ON ws.ws_sold_date_sk = d.d_date_sk
   AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   AND ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site we
    ON ws.ws_web_site_sk = we.web_site_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
   AND wr.wr_order_number = ws.ws_order_number
   AND wr.wr_item_sk = ws.ws_item_sk
JOIN reason r
    ON wr.wr_reason_sk = r.r_reason_sk
WHERE d.d_year = 2001
  AND s.s_state = 'CA'
  AND w.w_state = 'TX'
  AND we.web_market_manager = 'Eldon Snow'
  AND inv.inv_quantity_on_hand > 100
GROUP BY
    d.d_year,
    s.s_store_name,
    w.w_warehouse_name,
    sm.sm_type,
    we.web_name,
    r.r_reason_desc
ORDER BY total_catalog_sales DESC
LIMIT 100
