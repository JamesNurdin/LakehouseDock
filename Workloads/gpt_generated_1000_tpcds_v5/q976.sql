WITH avg_return_by_state AS (
    SELECT ca.ca_state,
           AVG(cr.cr_return_amount) AS avg_return_amount
    FROM catalog_returns cr
    JOIN customer_address ca
      ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    GROUP BY ca.ca_state
)
SELECT DISTINCT state,
                total_return_amount,
                return_cnt
FROM (
    SELECT ca.ca_state AS state,
           SUM(cr.cr_return_amount) AS total_return_amount,
           COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN customer_address ca
      ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE cr.cr_return_ship_cost > 50
      AND cr.cr_reversed_charge < 80
      AND ca.ca_suite_number LIKE 'Suite %'
      AND cr.cr_return_amount > (
            SELECT a.avg_return_amount
            FROM avg_return_by_state a
            WHERE a.ca_state = ca.ca_state
        )
    GROUP BY ca.ca_state

    UNION ALL

    SELECT ca.ca_state AS state,
           SUM(cr.cr_return_amount) AS total_return_amount,
           COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN customer_address ca
      ON cr.cr_returning_addr_sk = ca.ca_address_sk
    WHERE cr.cr_return_ship_cost BETWEEN 40 AND 200
      AND cr.cr_reversed_charge > 20
      AND ca.ca_city = 'Seattle'
      AND ca.ca_suite_number LIKE 'Suite 1%'
      AND EXISTS (
            SELECT 1
            FROM customer_address ca2
            WHERE ca2.ca_state = ca.ca_state
              AND ca2.ca_suite_number = 'Suite 130'
        )
    GROUP BY ca.ca_state
) combined
ORDER BY total_return_amount DESC
LIMIT 100
