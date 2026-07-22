SELECT
    d.d_year,
    cc.cc_name,
    p.p_promo_name,
    w.w_warehouse_name,
    ws.web_name,
    SUM(ss.ss_net_paid) AS total_store_sales,
    SUM(cs.cs_net_paid) AS total_catalog_sales,
    SUM(ir.inv_quantity_on_hand) AS total_inventory_on_hand,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_store_tickets,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_catalog_orders,
    AVG(ir.inv_quantity_on_hand) AS avg_inventory_qty,
    MIN(cs.cs_net_paid) AS min_catalog_sale,
    MAX(ss.ss_net_paid) AS max_store_sale
FROM
    date_dim d
    JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN inventory ir ON ir.inv_warehouse_sk = w.w_warehouse_sk AND ir.inv_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
WHERE
    d.d_year = 2002
    AND cc.cc_state = 'CA'
    AND p.p_channel_email = 'N'
    AND ir.inv_quantity_on_hand > 500
    AND ib.ib_upper_bound <= 50000
    AND cs.cs_quantity > 1
GROUP BY
    d.d_year,
    cc.cc_name,
    p.p_promo_name,
    w.w_warehouse_name,
    ws.web_name
ORDER BY
    total_store_sales DESC
LIMIT 100
