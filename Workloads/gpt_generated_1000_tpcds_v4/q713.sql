SELECT
    d_sr.d_year AS year,
    d_sr.d_month_seq AS month_seq,
    p_cs.p_promo_name AS promo_name,
    r_sr.r_reason_desc AS return_reason,
    SUM(cs.cs_net_paid) AS total_sales_net_paid,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(ws.ws_net_paid) AS total_web_sales_net_paid,
    SUM(wr.wr_return_amt) AS total_web_return_amount,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_sales_orders,
    COUNT(DISTINCT c_sr.c_customer_id) AS distinct_customers,
    AVG(cs.cs_quantity) AS avg_quantity_sold,
    MIN(d_sr.d_date) AS min_date,
    MAX(d_sr.d_date) AS max_date
FROM store_returns sr
JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
JOIN customer c_sr ON sr.sr_customer_sk = c_sr.c_customer_sk
JOIN customer_demographics cd_sr ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
JOIN household_demographics hd_sr ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
JOIN income_band ib ON hd_sr.hd_income_band_sk = ib.ib_income_band_sk
JOIN catalog_sales cs ON cs.cs_bill_customer_sk = c_sr.c_customer_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN warehouse w_cs ON cs.cs_warehouse_sk = w_cs.w_warehouse_sk
JOIN promotion p_cs ON cs.cs_promo_sk = p_cs.p_promo_sk
JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
JOIN web_sales ws ON ws.ws_bill_customer_sk = c_sr.c_customer_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
WHERE
    d_sr.d_year = 2001
    AND cp.cp_department = 'Electronics'
    AND c_sr.c_birth_country = 'United States'
    AND ib.ib_upper_bound >= 50000
    AND p_cs.p_discount_active = 'Y'
    AND r_sr.r_reason_desc = 'Customer Not Satisfied'
    AND w_cs.w_state = 'CA'
    AND d_cr.d_moy = 12
    AND ws.ws_quantity > 5
GROUP BY
    d_sr.d_year,
    d_sr.d_month_seq,
    p_cs.p_promo_name,
    r_sr.r_reason_desc
ORDER BY
    total_sales_net_paid DESC
LIMIT 100
