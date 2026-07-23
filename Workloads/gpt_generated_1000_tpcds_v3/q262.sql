SELECT
    s.s_store_name,
    i.i_category,
    d.d_year,
    r.r_reason_desc,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_ext_sales_price) AS total_ext_sales_price,
    SUM(sr.sr_return_amt) AS total_return_amount,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    COUNT(DISTINCT sr.sr_ticket_number) AS distinct_returns
FROM tpcds.date_dim d
JOIN tpcds.store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
JOIN tpcds.store s ON sr.sr_store_sk = s.s_store_sk
JOIN tpcds.reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN tpcds.item i ON sr.sr_item_sk = i.i_item_sk
JOIN tpcds.household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN tpcds.customer c ON sr.sr_customer_sk = c.c_customer_sk
JOIN tpcds.catalog_sales cs ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN tpcds.call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN tpcds.ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN tpcds.warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN tpcds.web_page wp ON wp.wp_customer_sk = c.c_customer_sk
WHERE r.r_reason_id = 'AAAAAAAADAAAAAAA'
  AND i.i_category_id = 5
  AND s.s_state = 'CA'
  AND d.d_year = 2001
GROUP BY
    s.s_store_name,
    i.i_category,
    d.d_year,
    r.r_reason_desc
HAVING SUM(sr.sr_return_amt) > 1000
   AND SUM(cs.cs_net_paid) > 5000
ORDER BY total_net_paid DESC
LIMIT 100
