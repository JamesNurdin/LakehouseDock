WITH agg AS (
  SELECT
    cc.cc_name,
    cc.cc_manager,
    cc.cc_city,
    sm.sm_type,
    sm.sm_contract,
    ca.ca_state,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_return_tax) AS avg_return_tax,
    MIN(cr.cr_return_amount) AS min_return_amount,
    MAX(cr.cr_return_amount) AS max_return_amount
  FROM catalog_returns cr
  JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
  WHERE cc.cc_manager = 'Gregory Altman'
    AND cc.cc_city = 'Main'
    AND sm.sm_type = 'EXPRESS'
    AND sm.sm_contract = 'yVfotg7Tio3MVhBg6Bkn'
    AND ca.ca_state = 'TX'
    AND cr.cr_return_amount > 100
    AND cr.cr_return_quantity > 1
  GROUP BY
    cc.cc_name,
    cc.cc_manager,
    cc.cc_city,
    sm.sm_type,
    sm.sm_contract,
    ca.ca_state
)
SELECT
  cc_name,
  cc_manager,
  cc_city,
  sm_type,
  sm_contract,
  ca_state,
  distinct_orders,
  total_return_amount,
  avg_return_tax,
  min_return_amount,
  max_return_amount,
  SUM(total_return_amount) OVER (PARTITION BY sm_type ORDER BY total_return_amount DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_return_by_type,
  RANK() OVER (ORDER BY total_return_amount DESC) AS revenue_rank
FROM agg
ORDER BY total_return_amount DESC
LIMIT 100
