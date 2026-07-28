SELECT
    ca_bill.ca_state,
    d_sold.d_year,
    p.p_promo_name,
    sm.sm_type,
    r_cr.r_reason_desc,
    r_sr.r_reason_desc,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(sr.sr_return_amt) AS total_store_return_amount,
    SUM(wr.wr_return_amt) AS total_web_return_amount,
    COUNT(DISTINCT cs.cs_order_number) AS order_count
FROM catalog_sales cs
JOIN date_dim d_sold
  ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN promotion p
  ON cs.cs_promo_sk = p.p_promo_sk
JOIN customer_demographics cd_bill
  ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN household_demographics hd_bill
  ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN income_band ib
  ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
JOIN customer_address ca_bill
  ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN catalog_returns cr
  ON cr.cr_order_number = cs.cs_order_number
  AND cr.cr_item_sk = cs.cs_item_sk
JOIN date_dim d_return
  ON cr.cr_returned_date_sk = d_return.d_date_sk
JOIN reason r_cr
  ON cr.cr_reason_sk = r_cr.r_reason_sk
JOIN store_returns sr
  ON sr.sr_returned_date_sk = d_return.d_date_sk
JOIN "store" s
  ON sr.sr_store_sk = s.s_store_sk
JOIN reason r_sr
  ON sr.sr_reason_sk = r_sr.r_reason_sk
JOIN web_returns wr
  ON wr.wr_returned_date_sk = d_return.d_date_sk
JOIN web_page wp
  ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_web_creation
  ON wp.wp_creation_date_sk = d_web_creation.d_date_sk
GROUP BY
    ca_bill.ca_state,
    d_sold.d_year,
    p.p_promo_name,
    sm.sm_type,
    r_cr.r_reason_desc,
    r_sr.r_reason_desc
ORDER BY
    total_net_paid DESC
LIMIT 100
