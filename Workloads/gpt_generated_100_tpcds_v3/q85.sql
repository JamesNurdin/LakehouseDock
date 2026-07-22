/* Goal: Calculate yearly totals of store and web sales, returns and inventory by warehouse state and item brand for 2001, focusing on US warehouses, California call centers, dynamic web pages, and high‑cost promotions, and include subquery metrics. */
SELECT
    d.d_year AS year,
    w.w_state AS warehouse_state,
    i.i_brand AS brand,
    p_ss.p_promo_name AS promo_name,
    SUM(ss.ss_net_paid) AS total_store_sales,
    SUM(ws.ws_net_paid) AS total_web_sales,
    SUM(cr.cr_return_amount) AS total_returns,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_transactions,
    COUNT(DISTINCT ws.ws_order_number) AS web_orders,
    AVG(ws.ws_ext_discount_amt) AS avg_web_discount,
    (SELECT AVG(ws_all.ws_net_paid) FROM web_sales ws_all) AS overall_avg_ws_net_paid
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN time_dim t_ss ON ss.ss_sold_time_sk = t_ss.t_time_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p_ss ON ss.ss_promo_sk = p_ss.p_promo_sk
JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    AND ws.ws_item_sk = i.i_item_sk
JOIN time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
JOIN promotion p_ws ON ws.ws_promo_sk = p_ws.p_promo_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
    AND cr.cr_item_sk = i.i_item_sk
JOIN time_dim t_cr ON cr.cr_returned_time_sk = t_cr.t_time_sk
JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
    AND cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
    AND inv.inv_item_sk = i.i_item_sk
    AND inv.inv_warehouse_sk = w.w_warehouse_sk
WHERE d.d_year = 2001
  AND w.w_country = 'United States'
  AND cc.cc_state = 'CA'
  AND wp.wp_type = 'dynamic'
  AND p_ss.p_discount_active = 'Y'
  AND i.i_brand = 'Brand#12'
  AND EXISTS (
        SELECT 1 FROM promotion p2
        WHERE p2.p_item_sk = i.i_item_sk
          AND p2.p_cost > 1000
    )
GROUP BY d.d_year, w.w_state, i.i_brand, p_ss.p_promo_name
ORDER BY year, warehouse_state, brand
