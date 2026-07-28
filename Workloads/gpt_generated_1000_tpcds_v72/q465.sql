WITH inv_agg AS (
    SELECT
        i.i_item_sk,
        w.w_warehouse_sk,
        SUM(inv.inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    GROUP BY i.i_item_sk, w.w_warehouse_sk
)
SELECT
    d.d_year,
    i.i_category,
    sm.sm_type,
    SUM(ss.ss_ext_sales_price) AS store_sales_total,
    SUM(cs.cs_ext_sales_price) AS catalog_sales_total,
    SUM(ws.ws_ext_sales_price) AS web_sales_total,
    SUM(ss.ss_ext_sales_price + cs.cs_ext_sales_price + ws.ws_ext_sales_price) AS total_sales,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_orders,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
    COUNT(DISTINCT ws.ws_order_number) AS web_orders,
    SUM(CASE WHEN sm.sm_code = 'AIR' THEN ss.ss_ext_sales_price ELSE 0 END) AS air_ship_store_sales,
    MIN(ss.ss_net_profit) AS min_store_profit,
    MAX(ss.ss_net_profit) AS max_store_profit,
    ia.total_qty_on_hand
FROM date_dim d
JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w_cs ON cs.cs_warehouse_sk = w_cs.w_warehouse_sk
JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
    AND cr.cr_order_number = cs.cs_order_number
JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
JOIN warehouse w_ws ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    AND wr.wr_order_number = ws.ws_order_number
JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
    AND sr.sr_ticket_number = ss.ss_ticket_number
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
    AND inv.inv_item_sk = i.i_item_sk
JOIN warehouse w_inv ON inv.inv_warehouse_sk = w_inv.w_warehouse_sk
JOIN inv_agg ia ON ia.i_item_sk = i.i_item_sk
    AND ia.w_warehouse_sk = w_cs.w_warehouse_sk
JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
WHERE d.d_year = 2001
  AND ca.ca_state = 'CA'
  AND sm.sm_code IN ('AIR', 'SEA')
  AND p.p_discount_active = 'Y'
  AND i.i_brand = 'Brand#12'
  AND w_cs.w_state = 'CA'
GROUP BY d.d_year, i.i_category, sm.sm_type, ia.total_qty_on_hand
ORDER BY total_sales DESC
LIMIT 100
