SELECT
    i_ret.i_category AS item_category,
    i_ret.i_item_sk AS item_sk,
    w_r.w_warehouse_name AS return_warehouse,
    cp.cp_department AS department,
    r.r_reason_desc AS return_reason,
    hd_refunded.hd_income_band_sk AS income_band_sk,
    COUNT(DISTINCT cr.cr_order_number) AS num_returns,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    SUM(ws.ws_net_profit) AS total_sales_profit,
    SUM(ws.ws_quantity) AS total_sales_quantity,
    SUM(ws.ws_ext_sales_price) AS total_sales_revenue,
    SUM(inv.inv_quantity_on_hand) AS inventory_on_hand,
    (SELECT sum(inv2.inv_quantity_on_hand)
       FROM inventory inv2
      WHERE inv2.inv_item_sk = i_ret.i_item_sk) AS total_inventory_all_warehouses,
    (SELECT max(ib2.ib_upper_bound)
       FROM income_band ib2
      WHERE ib2.ib_income_band_sk = hd_refunded.hd_income_band_sk) AS max_income_upper_bound
FROM catalog_returns cr
JOIN time_dim tr ON cr.cr_returned_time_sk = tr.t_time_sk
JOIN item i_ret ON cr.cr_item_sk = i_ret.i_item_sk
JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
JOIN ship_mode smr ON cr.cr_ship_mode_sk = smr.sm_ship_mode_sk
JOIN warehouse w_r ON cr.cr_warehouse_sk = w_r.w_warehouse_sk
JOIN customer c_refunded ON cr.cr_refunded_customer_sk = c_refunded.c_customer_sk
JOIN customer_address ca_refunded ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
JOIN customer_demographics cd_refunded ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
JOIN household_demographics hd_refunded ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
JOIN income_band ib_refunded ON hd_refunded.hd_income_band_sk = ib_refunded.ib_income_band_sk
JOIN inventory inv ON inv.inv_item_sk = i_ret.i_item_sk AND inv.inv_warehouse_sk = w_r.w_warehouse_sk
JOIN web_sales ws ON ws.ws_item_sk = i_ret.i_item_sk
JOIN time_dim ts ON ws.ws_sold_time_sk = ts.t_time_sk
JOIN customer c_bill ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN income_band ib_bill ON hd_bill.hd_income_band_sk = ib_bill.ib_income_band_sk
JOIN ship_mode sm_s ON ws.ws_ship_mode_sk = sm_s.sm_ship_mode_sk
JOIN warehouse w_s ON ws.ws_warehouse_sk = w_s.w_warehouse_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
WHERE cr.cr_return_amount > 0
GROUP BY
    i_ret.i_category,
    i_ret.i_item_sk,
    w_r.w_warehouse_name,
    cp.cp_department,
    r.r_reason_desc,
    hd_refunded.hd_income_band_sk
ORDER BY total_return_amount DESC
LIMIT 100
