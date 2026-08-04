WITH
  refunded_high AS (
    SELECT c.c_customer_id
    FROM catalog_returns cr
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE ca.ca_zip = '57783'
    GROUP BY c.c_customer_id
    HAVING SUM(cr.cr_return_amount) > 1000
  ),
  returning_high_tax AS (
    SELECT c.c_customer_id
    FROM catalog_returns cr
    JOIN customer c ON cr.cr_returning_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cr.cr_returning_addr_sk = ca.ca_address_sk
    WHERE ca.ca_state = 'CA'
    GROUP BY c.c_customer_id
    HAVING AVG(cr.cr_return_tax) > 15
  ),
  recent_review AS (
    SELECT c.c_customer_id
    FROM customer c
    WHERE c.c_last_review_date > 2452500
  ),
  high_ship_cost_customers AS (
    SELECT DISTINCT c.c_customer_id
    FROM catalog_returns cr
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    WHERE cr.cr_return_ship_cost > 1500
      AND EXISTS (
        SELECT 1
        FROM customer_address ca
        WHERE ca.ca_address_sk = c.c_current_addr_sk
          AND ca.ca_zip LIKE '9%'
      )
  ),
  intersected AS (
    SELECT c_customer_id FROM refunded_high
    INTERSECT
    SELECT c_customer_id FROM returning_high_tax
  ),
  final_set AS (
    SELECT c_customer_id FROM intersected
    EXCEPT
    SELECT c_customer_id FROM recent_review
  )
SELECT f.c_customer_id
FROM final_set f
UNION ALL
SELECT h.c_customer_id
FROM high_ship_cost_customers h
ORDER BY c_customer_id
LIMIT 100
