SELECT
    w.w_state AS warehouse_state,
    sm_cs.sm_type AS shipping_type,
    CASE
        WHEN ib.ib_upper_bound >= 100000 THEN 'High'
        WHEN ib.ib_upper_bound >= 50000 THEN 'Medium'
        ELSE 'Low'
    END AS income_category,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_catalog_orders,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_web_orders,
    COUNT(DISTINCT cs.cs_item_sk) AS distinct_catalog_items,
    SUM(cs.cs_net_profit) AS total_catalog_net_profit,
    SUM(ws.ws_net_profit) AS total_web_net_profit,
    SUM(cr.cr_return_amount) AS total_catalog_returns,
    SUM(wr.wr_return_amt) AS total_web_returns,
    AVG(p.p_cost) AS avg_promo_cost,
    SUM(COALESCE(inv.inv_quantity_on_hand, 0)) AS total_inventory_quantity
FROM catalog_sales cs
JOIN time_dim t_sales ON cs.cs_sold_time_sk = t_sales.t_time_sk
JOIN customer cust_bill ON cs.cs_bill_customer_sk = cust_bill.c_customer_sk
JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer cust_ship ON cs.cs_ship_customer_sk = cust_ship.c_customer_sk
JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN ship_mode sm_cs ON cs.cs_ship_mode_sk = sm_cs.sm_ship_mode_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    AND cr.cr_item_sk = cs.cs_item_sk
JOIN time_dim t_return ON cr.cr_returned_time_sk = t_return.t_time_sk
JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
JOIN ship_mode sm_cr ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
JOIN customer cr_refunded_cust ON cr.cr_refunded_customer_sk = cr_refunded_cust.c_customer_sk
JOIN customer_demographics cr_refunded_cdemo ON cr.cr_refunded_cdemo_sk = cr_refunded_cdemo.cd_demo_sk
JOIN household_demographics cr_refunded_hdemo ON cr.cr_refunded_hdemo_sk = cr_refunded_hdemo.hd_demo_sk
JOIN customer_address cr_refunded_addr ON cr.cr_refunded_addr_sk = cr_refunded_addr.ca_address_sk
JOIN customer cr_returning_cust ON cr.cr_returning_customer_sk = cr_returning_cust.c_customer_sk
JOIN customer_demographics cr_returning_cdemo ON cr.cr_returning_cdemo_sk = cr_returning_cdemo.cd_demo_sk
JOIN household_demographics cr_returning_hdemo ON cr.cr_returning_hdemo_sk = cr_returning_hdemo.hd_demo_sk
JOIN customer_address cr_returning_addr ON cr.cr_returning_addr_sk = cr_returning_addr.ca_address_sk
LEFT JOIN inventory inv ON inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN income_band ib ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
JOIN web_sales ws ON ws.ws_warehouse_sk = w.w_warehouse_sk
    AND ws.ws_ship_mode_sk = sm_cs.sm_ship_mode_sk
    AND ws.ws_bill_customer_sk = cust_bill.c_customer_sk
    AND ws.ws_ship_customer_sk = cust_ship.c_customer_sk
    AND ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    AND ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
    AND ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    AND ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
    AND ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    AND ws.ws_ship_addr_sk = ca_ship.ca_address_sk
    AND ws.ws_promo_sk = p.p_promo_sk
JOIN time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    AND wr.wr_item_sk = ws.ws_item_sk
JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
JOIN customer wr_refunded_cust ON wr.wr_refunded_customer_sk = wr_refunded_cust.c_customer_sk
JOIN customer_demographics wr_refunded_cdemo ON wr.wr_refunded_cdemo_sk = wr_refunded_cdemo.cd_demo_sk
JOIN household_demographics wr_refunded_hdemo ON wr.wr_refunded_hdemo_sk = wr_refunded_hdemo.hd_demo_sk
JOIN customer_address wr_refunded_addr ON wr.wr_refunded_addr_sk = wr_refunded_addr.ca_address_sk
JOIN customer wr_returning_cust ON wr.wr_returning_customer_sk = wr_returning_cust.c_customer_sk
JOIN customer_demographics wr_returning_cdemo ON wr.wr_returning_cdemo_sk = wr_returning_cdemo.cd_demo_sk
JOIN household_demographics wr_returning_hdemo ON wr.wr_returning_hdemo_sk = wr_returning_hdemo.hd_demo_sk
JOIN customer_address wr_returning_addr ON wr.wr_returning_addr_sk = wr_returning_addr.ca_address_sk
WHERE
    t_sales.t_hour = 13
    AND cust_bill.c_birth_year = 1975
    AND hd_bill.hd_buy_potential = '1001-5000'
    AND ib.ib_upper_bound <= 50000
    AND p.p_discount_active = 'Y'
    AND r_cr.r_reason_desc = 'Damaged Item'
    AND w.w_state = 'CA'
    AND cs.cs_item_sk IN (SELECT inv2.inv_item_sk FROM inventory inv2 WHERE inv2.inv_quantity_on_hand > 500)
GROUP BY
    w.w_state,
    sm_cs.sm_type,
    ib.ib_upper_bound
ORDER BY
    total_catalog_net_profit DESC
LIMIT 100
