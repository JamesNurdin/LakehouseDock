SELECT
    cr.cr_order_number,
    cr.cr_return_amount,
    ca.ca_city,
    ca.ca_state
FROM tpcds.catalog_returns cr
JOIN tpcds.customer_address ca
  ON cr.cr_refunded_addr_sk = ca.ca_address_sk
WHERE cr.cr_reversed_charge > 50
  AND ca.ca_location_type = 'apartment'
LIMIT 100
