SELECT
  cc.cc_state,
  cc.cc_city,
  COUNT(DISTINCT cc.cc_call_center_id) AS num_call_centers,
  SUM(cc.cc_employees) AS total_employees,
  AVG(cc.cc_tax_percentage) AS avg_tax_pct,
  COUNT(DISTINCT ca.ca_address_id) AS num_customer_addresses,
  AVG(ABS(cc.cc_gmt_offset - ca.ca_gmt_offset)) AS avg_gmt_offset_diff,
  MAX(sm.sm_type) AS ship_mode_type,
  SUM(CASE WHEN t.t_shift = 'Night' THEN 1 ELSE 0 END) AS night_shift_count
FROM call_center cc
JOIN customer_address ca
  ON cc.cc_state = ca.ca_state
  AND cc.cc_city = ca.ca_city
  AND cc.cc_zip = ca.ca_zip
JOIN ship_mode sm
  ON sm.sm_carrier = 'UPS'
JOIN time_dim t
  ON t.t_time_sk = cc.cc_open_date_sk
WHERE cc.cc_country = 'United States'
  AND cc.cc_state IN ('TN', 'GA')
  AND cc.cc_gmt_offset = -5.00
  AND ca.ca_location_type = 'Residential'
  AND t.t_hour BETWEEN 9 AND 17
GROUP BY cc.cc_state, cc.cc_city
HAVING COUNT(DISTINCT cc.cc_call_center_id) > 0
ORDER BY total_employees DESC
LIMIT 50
