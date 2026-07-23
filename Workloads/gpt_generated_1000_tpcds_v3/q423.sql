WITH avg_discount AS (
    SELECT AVG(cs2.cs_ext_discount_amt) AS avg_disc
    FROM catalog_sales cs2
)
SELECT
    w.w_state AS warehouse_state,
    cc.cc_division_name AS division_name,
    p.p_promo_name AS promo_name,
    i.i_brand AS item_brand,
    ib_bill.ib_lower_bound AS income_lower,
    ib_ship.ib_upper_bound AS income_upper,
    r.r_reason_desc AS return_reason,
    COUNT(DISTINCT cs.cs_order_number) AS orders_count,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(cr.cr_net_loss) AS total_net_loss,
    (SELECT avg_disc FROM avg_discount) AS avg_discount,
    SUM(CASE WHEN cs.cs_ext_discount_amt > (SELECT avg_disc FROM avg_discount) THEN cs.cs_ext_discount_amt ELSE 0 END) AS high_discount_sum
FROM catalog_sales cs
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN customer c_bill
    ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
JOIN household_demographics hd_bill
    ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN income_band ib_bill
    ON hd_bill.hd_income_band_sk = ib_bill.ib_income_band_sk
JOIN customer c_ship
    ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
JOIN household_demographics hd_ship
    ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN income_band ib_ship
    ON hd_ship.hd_income_band_sk = ib_ship.ib_income_band_sk
JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
   AND cr.cr_call_center_sk = cc.cc_call_center_sk
   AND cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   AND cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
   AND cr.cr_warehouse_sk = w.w_warehouse_sk
   AND cr.cr_item_sk = i.i_item_sk
JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
JOIN customer c_refund
    ON cr.cr_refunded_customer_sk = c_refund.c_customer_sk
JOIN household_demographics hd_refund
    ON cr.cr_refunded_hdemo_sk = hd_refund.hd_demo_sk
JOIN customer c_return
    ON cr.cr_returning_customer_sk = c_return.c_customer_sk
JOIN household_demographics hd_return
    ON cr.cr_returning_hdemo_sk = hd_return.hd_demo_sk
JOIN store_sales ss
    ON ss.ss_item_sk = i.i_item_sk
JOIN customer c_ss
    ON ss.ss_customer_sk = c_ss.c_customer_sk
JOIN household_demographics hd_ss
    ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
JOIN promotion p_ss
    ON ss.ss_promo_sk = p_ss.p_promo_sk
WHERE cp.cp_type = 'monthly'
  AND sm.sm_code = 'AIR'
  AND w.w_gmt_offset = -6.00
GROUP BY
    w.w_state,
    cc.cc_division_name,
    p.p_promo_name,
    i.i_brand,
    ib_bill.ib_lower_bound,
    ib_ship.ib_upper_bound,
    r.r_reason_desc
ORDER BY total_net_profit DESC
LIMIT 100
