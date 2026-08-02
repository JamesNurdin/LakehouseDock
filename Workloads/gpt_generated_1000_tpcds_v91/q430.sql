WITH preferred_returns AS (
    SELECT
        d.d_date AS return_date,
        COUNT(*) AS return_cnt,
        SUM(cr.cr_return_amount) AS total_return_amount,
        AVG(cr.cr_return_amount) AS avg_return_amount,
        'Preferred' AS customer_type
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE c.c_preferred_cust_flag = 'Y'
      AND d.d_date BETWEEN DATE '2000-01-01' AND DATE '2000-01-31'
      AND EXISTS (
          SELECT 1
          FROM customer_address ca2
          WHERE ca2.ca_address_sk = c.c_current_addr_sk
            AND ca2.ca_state = 'CA'
      )
    GROUP BY d.d_date
)
SELECT
    return_date,
    return_cnt,
    total_return_amount,
    avg_return_amount,
    customer_type
FROM preferred_returns
UNION
SELECT
    d.d_date AS return_date,
    COUNT(*) AS return_cnt,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    'Non-Preferred' AS customer_type
FROM catalog_returns cr
JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
WHERE c.c_preferred_cust_flag = 'N'
  AND d.d_date BETWEEN DATE '2000-02-01' AND DATE '2000-02-28'
  AND c.c_current_addr_sk IN (
      SELECT ca3.ca_address_sk
      FROM customer_address ca3
      WHERE ca3.ca_state IN ('TX', 'NY')
  )
GROUP BY d.d_date
ORDER BY return_date ASC, customer_type
LIMIT 100
