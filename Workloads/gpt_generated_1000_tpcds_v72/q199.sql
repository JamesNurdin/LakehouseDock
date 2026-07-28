WITH item_stats AS (
   SELECT
     i.i_item_sk,
     i.i_item_id,
     i.i_product_name,
     i.i_current_price,
     inv.inv_quantity_on_hand,
     AVG(p.p_cost) AS avg_promo_cost
   FROM item i
   JOIN inventory inv
     ON i.i_item_sk = inv.inv_item_sk
   JOIN promotion p
     ON i.i_item_sk = p.p_item_sk
   WHERE i.i_current_price BETWEEN 100 AND 500
     AND inv.inv_quantity_on_hand > 0
   GROUP BY i.i_item_sk, i.i_item_id, i.i_product_name, i.i_current_price, inv.inv_quantity_on_hand
)
SELECT
  i_stats.i_item_id,
  i_stats.i_product_name,
  i_stats.i_current_price,
  i_stats.inv_quantity_on_hand,
  i_stats.avg_promo_cost,
  hd.hd_vehicle_count,
  ib.ib_lower_bound,
  ib.ib_upper_bound,
  ca.ca_state,
  r.r_reason_desc,
  td_cr.t_meal_time AS cr_meal_time,
  td_wr.t_meal_time AS wr_meal_time,
  cr.cr_return_quantity,
  cr.cr_return_amount,
  cr.cr_net_loss,
  wr.wr_return_quantity,
  wr.wr_return_amt,
  wr.wr_net_loss,
  CASE
    WHEN (cr.cr_net_loss + wr.wr_net_loss) > 500 THEN 'High'
    ELSE 'Low'
  END AS loss_severity,
  (SELECT SUM(cr2.cr_return_quantity)
     FROM catalog_returns cr2
    WHERE cr2.cr_item_sk = i_stats.i_item_sk) AS total_return_qty_all_time,
  ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY (cr.cr_net_loss + wr.wr_net_loss) DESC) AS rn_category
FROM catalog_returns cr
JOIN item i
  ON cr.cr_item_sk = i.i_item_sk
JOIN web_returns wr
  ON wr.wr_item_sk = i.i_item_sk
JOIN item_stats i_stats
  ON i.i_item_sk = i_stats.i_item_sk
JOIN time_dim td_cr
  ON cr.cr_returned_time_sk = td_cr.t_time_sk
JOIN time_dim td_wr
  ON wr.wr_returned_time_sk = td_wr.t_time_sk
JOIN reason r
  ON cr.cr_reason_sk = r.r_reason_sk
JOIN household_demographics hd
  ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN customer_address ca
  ON cr.cr_refunded_addr_sk = ca.ca_address_sk
JOIN web_page wp
  ON wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE td_cr.t_meal_time = 'dinner'
  AND td_wr.t_meal_time = 'dinner'
  AND cr.cr_return_amount > 500
  AND wr.wr_return_amt > 400
  AND i.i_current_price < 300
  AND ib.ib_lower_bound >= 30000
ORDER BY loss_severity DESC, cr.cr_net_loss DESC
LIMIT 100
