SELECT
    ca.ca_state,
    ca.ca_location_type,
    SUM(cr.cr_return_amount) AS total_return_amount,
    COUNT(*) AS return_cnt
FROM catalog_returns cr
JOIN customer_address ca
  ON cr.cr_refunded_addr_sk = ca.ca_address_sk
WHERE cr.cr_ship_mode_sk = 16
  AND cr.cr_return_amount > 100
  AND ca.ca_location_type = 'condo'
GROUP BY ca.ca_state, ca.ca_location_type
ORDER BY total_return_amount DESC
LIMIT 100
