SELECT
  ca_state,
  COUNT(DISTINCT c_customer_sk) AS num_customers
FROM
  customer
JOIN
  customer_address
    ON customer.c_current_addr_sk = customer_address.ca_address_sk
WHERE
  customer.c_last_review_date > 2452500
  AND customer.c_email_address LIKE '%@%.org'
GROUP BY
  ca_state
ORDER BY
  num_customers DESC
LIMIT 10
