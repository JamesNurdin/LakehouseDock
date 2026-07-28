WITH sr_agg AS (
  SELECT
    sr_item_sk,
    sr_reason_sk,
    SUM(sr_return_quantity) AS total_qty,
    SUM(sr_return_amt) AS total_return_amt,
    SUM(sr_net_loss) AS total_net_loss
  FROM store_returns
  WHERE sr_return_quantity > 0
  GROUP BY sr_item_sk, sr_reason_sk
)
SELECT
  i.i_item_id,
  i.i_manufact_id,
  p.p_promo_name,
  r.r_reason_desc,
  ib.ib_lower_bound,
  ca.ca_state,
  c.c_salutation,
  t.t_meal_time,
  sr_agg.total_qty,
  sr_agg.total_return_amt,
  cr.cr_return_amount,
  cr.cr_net_loss
FROM sr_agg
JOIN item i ON sr_agg.sr_item_sk = i.i_item_sk
JOIN reason r ON sr_agg.sr_reason_sk = r.r_reason_sk
JOIN promotion p ON p.p_item_sk = i.i_item_sk
JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
WHERE i.i_manufact_id IN (52, 214)
  AND t.t_meal_time = 'breakfast'
  AND r.r_reason_desc LIKE '%damaged%'
  AND ib.ib_lower_bound >= 30000
  AND p.p_discount_active = 'Y'
  AND EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_refunded_customer_sk = c.c_customer_sk
          AND cr2.cr_returned_date_sk BETWEEN 2452100 AND 2452600
  )
ORDER BY sr_agg.total_return_amt DESC
LIMIT 100
