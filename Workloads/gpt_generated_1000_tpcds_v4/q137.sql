SELECT
    d_cs.d_year AS year,
    s.s_store_name,
    i.i_category,
    SUM(cs.cs_net_paid) AS total_catalog_sales,
    SUM(cr.cr_return_amount) AS total_catalog_returns,
    SUM(ss.ss_net_paid) AS total_store_sales,
    SUM(sr.sr_return_amt) AS total_store_returns,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    CASE
        WHEN SUM(cs.cs_net_profit) > 100000 THEN 'HIGH'
        ELSE 'LOW'
    END AS profit_flag
FROM catalog_sales cs
JOIN date_dim d_cs ON cs.cs_sold_date_sk = d_cs.d_date_sk
JOIN time_dim t_cs ON cs.cs_sold_time_sk = t_cs.t_time_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p_cat ON cs.cs_promo_sk = p_cat.p_promo_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN customer c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer c_ship ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    AND cr.cr_item_sk = cs.cs_item_sk
JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
JOIN time_dim t_cr ON cr.cr_returned_time_sk = t_cr.t_time_sk
JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
JOIN date_dim d_ss ON ss.ss_sold_date_sk = d_ss.d_date_sk
JOIN time_dim t_ss ON ss.ss_sold_time_sk = t_ss.t_time_sk
JOIN promotion p_store ON ss.ss_promo_sk = p_store.p_promo_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    AND sr.sr_item_sk = ss.ss_item_sk
JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    AND inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
JOIN web_site ws ON ws.web_open_date_sk = d_cs.d_date_sk
WHERE d_cs.d_year = 2001
  AND s.s_state = 'CA'
  AND p_cat.p_channel_email = 'Y'
GROUP BY
    d_cs.d_year,
    s.s_store_name,
    i.i_category
ORDER BY total_catalog_sales DESC
LIMIT 100
