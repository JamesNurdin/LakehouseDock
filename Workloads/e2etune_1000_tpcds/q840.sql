SELECT
  i.i_category AS category,
  s.s_state AS state,
  sm.sm_type AS ship_mode_type,
  SUM(sr.sr_net_loss) AS total_store_net_loss,
  SUM(cr.cr_net_loss) AS total_catalog_net_loss,
  SUM(sr.sr_return_quantity) AS total_store_return_qty,
  SUM(cr.cr_return_quantity) AS total_catalog_return_qty,
  AVG(sr.sr_return_amt_inc_tax) AS avg_store_return_amount,
  AVG(cr.cr_return_amt_inc_tax) AS avg_catalog_return_amount,
  COALESCE(SUM(inv.inv_quantity_on_hand), 0) AS total_inventory_on_hand,
  COUNT(DISTINCT p.p_promo_id) AS distinct_promo_count
FROM store_returns sr
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN item i ON sr.sr_item_sk = i.i_item_sk
LEFT JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
LEFT JOIN promotion p ON i.i_item_sk = p.p_item_sk
LEFT JOIN catalog_returns cr ON i.i_item_sk = cr.cr_item_sk
LEFT JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
WHERE
  sr.sr_returned_date_sk BETWEEN 20000 AND 30000
  AND i.i_current_price > 50
  AND (cr.cr_fee IS NULL OR cr.cr_fee > 20)
  AND (p.p_discount_active = 'Y' OR p.p_discount_active IS NULL)
GROUP BY
  i.i_category,
  s.s_state,
  sm.sm_type
HAVING
  SUM(sr.sr_net_loss) + SUM(cr.cr_net_loss) > 1000
ORDER BY
  total_store_net_loss DESC
LIMIT 100
