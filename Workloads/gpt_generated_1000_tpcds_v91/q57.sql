WITH store_cte AS (
   SELECT
      sr.sr_returned_date_sk,
      d.d_date,
      d.d_year,
      d.d_month_seq,
      c.c_customer_id,
      c.c_first_name,
      c.c_last_name,
      ca.ca_address_id,
      hd.hd_dep_count,
      hd.hd_vehicle_count,
      ib.ib_lower_bound,
      ib.ib_upper_bound,
      r.r_reason_desc,
      sr.sr_reason_sk,
      sr.sr_return_quantity,
      sr.sr_return_amt,
      sr.sr_net_loss
   FROM store_returns sr
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
   JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
   JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
),
catalog_cte AS (
   SELECT
      cr.cr_returned_date_sk,
      d.d_date,
      d.d_year,
      d.d_month_seq,
      c.c_customer_id AS cr_customer_id,
      ca.ca_address_id AS cr_address_id,
      hd.hd_dep_count,
      hd.hd_vehicle_count,
      ib.ib_lower_bound,
      ib.ib_upper_bound,
      r.r_reason_desc,
      sm.sm_ship_mode_id,
      cr.cr_return_quantity,
      cr.cr_return_amount,
      cr.cr_return_tax,
      cr.cr_return_amt_inc_tax,
      cr.cr_fee,
      cr.cr_return_ship_cost,
      cr.cr_refunded_cash,
      cr.cr_store_credit,
      cr.cr_net_loss,
      p.p_promo_id,
      p.p_discount_active,
      cr.cr_reason_sk
   FROM catalog_returns cr
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
   JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
   JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
   JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN promotion p ON p.p_start_date_sk = d.d_date_sk
)
SELECT
   s.c_customer_id,
   s.c_first_name,
   s.c_last_name,
   s.d_year,
   s.d_month_seq,
   s.sr_return_quantity,
   s.sr_return_amt,
   s.sr_net_loss AS store_net_loss,
   c.cr_return_quantity,
   c.cr_return_amount,
   c.cr_return_tax,
   c.cr_return_amt_inc_tax,
   c.cr_fee,
   c.cr_return_ship_cost,
   c.cr_refunded_cash,
   c.cr_store_credit,
   c.cr_net_loss AS catalog_net_loss,
   (s.sr_net_loss + c.cr_net_loss) AS total_net_loss,
   DENSE_RANK() OVER (ORDER BY (s.sr_net_loss + c.cr_net_loss) DESC) AS loss_rank,
   CASE WHEN c.p_discount_active = 'Y' THEN 'Active Promo' ELSE 'Inactive Promo' END AS promo_status
FROM store_cte s
JOIN catalog_cte c ON s.c_customer_id = c.cr_customer_id
WHERE
   s.d_year = 2001
   AND s.hd_dep_count >= 1
   AND s.hd_vehicle_count >= 0
   AND s.ib_lower_bound >= 30000
   AND c.cr_return_tax > 0
   AND c.sm_ship_mode_id IS NOT NULL
   AND c.p_discount_active = 'Y'
   AND NOT EXISTS (
       SELECT 1
       FROM reason r2
       WHERE r2.r_reason_sk = s.sr_reason_sk
         AND r2.r_reason_desc = 'Defective'
   )
   AND EXISTS (
       SELECT 1
       FROM promotion p2
       WHERE p2.p_promo_id = c.p_promo_id
         AND p2.p_discount_active = 'Y'
         AND p2.p_start_date_sk <= s.sr_returned_date_sk
         AND p2.p_end_date_sk >= s.sr_returned_date_sk
   )
ORDER BY total_net_loss DESC
LIMIT 100
