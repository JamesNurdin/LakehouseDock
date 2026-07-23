SELECT
    i.i_category AS item_category,
    cp.cp_department AS catalog_department,
    sm.sm_type AS ship_mode_type,
    td_cr.t_hour AS return_hour,
    ib.ib_lower_bound AS income_lower,
    ib.ib_upper_bound AS income_upper,
    SUM(cr.cr_return_amt_inc_tax) AS catalog_return_total,
    SUM(sr.sr_return_amt_inc_tax) AS store_return_total,
    SUM(wr.wr_return_amt_inc_tax) AS web_return_total,
    SUM(cr.cr_return_amt_inc_tax) + SUM(sr.sr_return_amt_inc_tax) + SUM(wr.wr_return_amt_inc_tax) AS total_return_amount,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_orders,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_tickets,
    COUNT(DISTINCT wr.wr_order_number) AS web_orders,
    AVG(p.p_cost) AS avg_promotion_cost
FROM catalog_returns cr
JOIN catalog_page cp
  ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
  ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN time_dim td_cr
  ON cr.cr_returned_time_sk = td_cr.t_time_sk
JOIN item i
  ON cr.cr_item_sk = i.i_item_sk
JOIN customer_demographics cd_ref
  ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
JOIN customer_demographics cd_ret
  ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
JOIN household_demographics hd_ref
  ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
JOIN household_demographics hd_ret
  ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
JOIN customer_address ca_ref
  ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
JOIN customer_address ca_ret
  ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
-- Store returns and related dimensions
JOIN store_returns sr
  ON sr.sr_item_sk = i.i_item_sk
JOIN time_dim td_sr
  ON sr.sr_return_time_sk = td_sr.t_time_sk
JOIN customer_demographics cd_sr
  ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
JOIN household_demographics hd_sr
  ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
JOIN customer_address ca_sr
  ON sr.sr_addr_sk = ca_sr.ca_address_sk
-- Web returns and related dimensions
JOIN web_returns wr
  ON wr.wr_item_sk = i.i_item_sk
JOIN time_dim td_wr
  ON wr.wr_returned_time_sk = td_wr.t_time_sk
JOIN web_page wp
  ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN customer_demographics cd_wr
  ON wr.wr_refunded_cdemo_sk = cd_wr.cd_demo_sk
JOIN household_demographics hd_wr
  ON wr.wr_refunded_hdemo_sk = hd_wr.hd_demo_sk
JOIN customer_address ca_wr
  ON wr.wr_refunded_addr_sk = ca_wr.ca_address_sk
-- Inventory, promotion, and income band
JOIN inventory inv
  ON inv.inv_item_sk = i.i_item_sk
JOIN promotion p
  ON p.p_item_sk = i.i_item_sk
JOIN income_band ib
  ON hd_ref.hd_income_band_sk = ib.ib_income_band_sk
WHERE EXISTS (
    SELECT 1
    FROM promotion p_active
    WHERE p_active.p_item_sk = i.i_item_sk
      AND p_active.p_discount_active = 'Y'
)
GROUP BY
    i.i_category,
    cp.cp_department,
    sm.sm_type,
    td_cr.t_hour,
    ib.ib_lower_bound,
    ib.ib_upper_bound
ORDER BY total_return_amount DESC
LIMIT 100
