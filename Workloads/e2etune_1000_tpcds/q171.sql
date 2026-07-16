WITH agg AS (
  SELECT
    sm.sm_ship_mode_id AS ship_mode_id,
    i.i_category AS item_category,
    td.t_hour AS hour_of_day,
    ca_ref.ca_country AS refund_country,
    ca_ret.ca_state AS return_state,
    COUNT(*) AS total_returns,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_net_loss) AS avg_net_loss,
    SUM(cr.cr_return_quantity) AS total_quantity,
    SUM(cr.cr_return_amount) / NULLIF(SUM(cr.cr_return_quantity), 0) AS avg_return_amount_per_qty
  FROM catalog_returns cr
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
  JOIN customer_address ca_ref ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
  JOIN customer_address ca_ret ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
  WHERE cr.cr_net_loss > 100
    AND td.t_hour BETWEEN 9 AND 17
    AND sm.sm_type = 'GROUND'
    AND ca_ref.ca_country = 'United States'
  GROUP BY
    sm.sm_ship_mode_id,
    i.i_category,
    td.t_hour,
    ca_ref.ca_country,
    ca_ret.ca_state
)
SELECT
  ship_mode_id,
  item_category,
  hour_of_day,
  refund_country,
  return_state,
  total_returns,
  total_return_amount,
  avg_net_loss,
  total_quantity,
  avg_return_amount_per_qty,
  CASE WHEN avg_net_loss > 500 THEN 'HIGH' ELSE 'LOW' END AS loss_category,
  RANK() OVER (PARTITION BY item_category ORDER BY total_return_amount DESC) AS ship_mode_rank_by_return_amount
FROM agg
ORDER BY item_category, ship_mode_rank_by_return_amount
