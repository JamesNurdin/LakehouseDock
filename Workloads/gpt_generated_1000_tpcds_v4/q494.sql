WITH refunded AS (
    SELECT
        ca.ca_state AS state,
        SUM(cr.cr_return_amt_inc_tax) AS total_amount
    FROM catalog_returns cr
    JOIN customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE ca.ca_state IN ('CA', 'TX')
      AND EXISTS (
          SELECT 1
          FROM household_demographics hd
          WHERE hd.hd_demo_sk = cr.cr_refunded_hdemo_sk
            AND hd.hd_vehicle_count > 0
      )
    GROUP BY ca.ca_state
),
returning AS (
    SELECT
        ca.ca_state AS state,
        SUM(cr.cr_return_amt_inc_tax) AS total_amount
    FROM catalog_returns cr
    JOIN customer_address ca
        ON cr.cr_returning_addr_sk = ca.ca_address_sk
    WHERE ca.ca_state IN ('CA', 'TX')
      AND EXISTS (
          SELECT 1
          FROM household_demographics hd
          WHERE hd.hd_demo_sk = cr.cr_returning_hdemo_sk
            AND hd.hd_vehicle_count > 0
      )
    GROUP BY ca.ca_state
)
SELECT
    state,
    total_amount,
    'refunded' AS return_category
FROM refunded
UNION ALL
SELECT
    state,
    total_amount,
    'returning' AS return_category
FROM returning
ORDER BY state, return_category
LIMIT 100
