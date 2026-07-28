SELECT
    cr.cr_order_number,
    cr.cr_return_amount,
    cr.cr_net_loss,
    cs.cs_net_paid,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    p.p_promo_name,
    r.r_reason_desc,
    sm.sm_carrier,
    td.t_hour,
    ROW_NUMBER() OVER (PARTITION BY td.t_hour ORDER BY cr.cr_net_loss DESC) AS loss_rank_hour,
    SUM(cr.cr_return_amount) OVER (
        PARTITION BY sm.sm_carrier
        ORDER BY cr.cr_returned_time_sk
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cum_return_by_carrier
FROM catalog_returns cr
JOIN catalog_sales cs
  ON cr.cr_order_number = cs.cs_order_number
  AND cr.cr_item_sk = cs.cs_item_sk
JOIN household_demographics hd
  ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN promotion p
  ON cs.cs_promo_sk = p.p_promo_sk
JOIN reason r
  ON cr.cr_reason_sk = r.r_reason_sk
JOIN ship_mode sm
  ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN time_dim td
  ON cr.cr_returned_time_sk = td.t_time_sk
WHERE td.t_hour BETWEEN 9 AND 17
  AND sm.sm_code IN ('AIR', 'SEA')
  AND r.r_reason_desc LIKE '%Did not%'
  AND ib.ib_lower_bound >= 50000
  AND p.p_discount_active = 'Y'
  AND cr.cr_return_quantity > 1
LIMIT 100
