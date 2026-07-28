/*
Goal: Calculate yearly sales and returns performance by store and item category for the year 2001, limited to California stores selling sports items. The query aggregates store, catalog and web sales, their corresponding returns, distinct customer count, average catalog promotion cost and minimum inventory on hand, while demonstrating a LEFT OUTER JOIN (catalog returns) and using COUNT(DISTINCT).
*/
SELECT
    s.s_store_name,
    d.d_year,
    i.i_category,
    SUM(ss.ss_net_paid)                                 AS total_store_sales,
    SUM(cs.cs_net_paid)                                 AS total_catalog_sales,
    SUM(ws.ws_net_paid)                                 AS total_web_sales,
    SUM(COALESCE(cr.cr_return_amount, 0))               AS total_catalog_returns,
    SUM(COALESCE(sr.sr_net_loss, 0))                    AS total_store_returns_loss,
    SUM(COALESCE(wr.wr_net_loss, 0))                    AS total_web_returns_loss,
    COUNT(DISTINCT c.c_customer_id)                     AS unique_customers,
    AVG(p_cat.p_cost)                                   AS avg_catalog_promo_cost,
    MIN(inv.inv_quantity_on_hand)                       AS min_inventory_on_hand
FROM
    store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t_ss ON ss.ss_sold_time_sk = t_ss.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p_ss ON ss.ss_promo_sk = p_ss.p_promo_sk
    /* catalog side */
    JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN promotion p_cat ON cs.cs_promo_sk = p_cat.p_promo_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm_cat ON cs.cs_ship_mode_sk = sm_cat.sm_ship_mode_sk
    JOIN warehouse w_cat ON cs.cs_warehouse_sk = w_cat.w_warehouse_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
    /* web side */
    JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN promotion p_ws ON ws.ws_promo_sk = p_ws.p_promo_sk
    JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    JOIN warehouse w_ws ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site webs ON ws.ws_web_site_sk = webs.web_site_sk
    LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    LEFT JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
    /* store returns */
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
    /* inventory */
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
                      AND inv.inv_warehouse_sk = w_cat.w_warehouse_sk
    JOIN date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
WHERE
    d.d_year = 2001
    AND i.i_category = 'Sports'
    AND s.s_state = 'CA'
    AND p_cat.p_discount_active = 'Y'
GROUP BY
    s.s_store_name,
    d.d_year,
    i.i_category
ORDER BY
    total_store_sales DESC
LIMIT 100
