WITH
    -- Re‑use date_dim for different roles
    d_sales AS (SELECT * FROM date_dim),
    d_sr_ret AS (SELECT * FROM date_dim),
    d_cs_sold AS (SELECT * FROM date_dim),
    d_cs_ship AS (SELECT * FROM date_dim),
    d_cr_ret AS (SELECT * FROM date_dim),
    d_wr_ret AS (SELECT * FROM date_dim)
SELECT
    s.s_store_name,
    d_sales.d_year,
    SUM(ss.ss_net_paid)               AS total_store_sales,
    SUM(sr.sr_net_loss)               AS total_store_return_loss,
    SUM(cs.cs_net_paid)               AS total_catalog_sales,
    SUM(cr.cr_net_loss)               AS total_catalog_return_loss,
    SUM(wr.wr_net_loss)               AS total_web_return_loss
FROM store_sales ss
JOIN d_sales d_sales
  ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN store s
  ON ss.ss_store_sk = s.s_store_sk
JOIN customer c_ss
  ON ss.ss_customer_sk = c_ss.c_customer_sk
JOIN promotion p_sale
  ON ss.ss_promo_sk = p_sale.p_promo_sk
-- store returns (second role for store and date_dim)
JOIN store_returns sr
  ON sr.sr_ticket_number = ss.ss_ticket_number
 AND sr.sr_item_sk = ss.ss_item_sk
JOIN d_sr_ret d_sr_ret
  ON sr.sr_returned_date_sk = d_sr_ret.d_date_sk
JOIN reason r_sr
  ON sr.sr_reason_sk = r_sr.r_reason_sk
JOIN store s_sr
  ON sr.sr_store_sk = s_sr.s_store_sk
-- catalog sales (multiple customer and date aliases)
JOIN catalog_sales cs
  ON cs.cs_item_sk = ss.ss_item_sk
JOIN d_cs_sold d_cs_sold
  ON cs.cs_sold_date_sk = d_cs_sold.d_date_sk
JOIN d_cs_ship d_cs_ship
  ON cs.cs_ship_date_sk = d_cs_ship.d_date_sk
JOIN customer c_bill
  ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
JOIN customer c_ship
  ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
JOIN call_center cc_cs
  ON cs.cs_call_center_sk = cc_cs.cc_call_center_sk
JOIN ship_mode sm_cs
  ON cs.cs_ship_mode_sk = sm_cs.sm_ship_mode_sk
JOIN promotion p_cat
  ON cs.cs_promo_sk = p_cat.p_promo_sk
-- catalog returns (linked by order number and item)
JOIN catalog_returns cr
  ON cr.cr_order_number = cs.cs_order_number
 AND cr.cr_item_sk = cs.cs_item_sk
JOIN d_cr_ret d_cr_ret
  ON cr.cr_returned_date_sk = d_cr_ret.d_date_sk
JOIN customer c_refund_cat
  ON cr.cr_refunded_customer_sk = c_refund_cat.c_customer_sk
JOIN customer c_returning_cat
  ON cr.cr_returning_customer_sk = c_returning_cat.c_customer_sk
JOIN call_center cc_cr
  ON cr.cr_call_center_sk = cc_cr.cc_call_center_sk
JOIN ship_mode sm_cr
  ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
JOIN reason r_cr
  ON cr.cr_reason_sk = r_cr.r_reason_sk
-- web returns (linked only through date and customer)
JOIN web_returns wr
  ON wr.wr_order_number = cs.cs_order_number
JOIN d_wr_ret d_wr_ret
  ON wr.wr_returned_date_sk = d_wr_ret.d_date_sk
JOIN customer c_refund_web
  ON wr.wr_refunded_customer_sk = c_refund_web.c_customer_sk
JOIN reason r_wr
  ON wr.wr_reason_sk = r_wr.r_reason_sk
-- inventory (joined on the same sales date for completeness)
JOIN inventory inv
  ON inv.inv_date_sk = d_sales.d_date_sk
WHERE d_sales.d_year = 2001
GROUP BY ROLLUP (s.s_store_name, d_sales.d_year)
HAVING SUM(ss.ss_net_paid) > 1000
ORDER BY s.s_store_name, d_sales.d_year
LIMIT 100
