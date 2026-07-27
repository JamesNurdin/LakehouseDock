WITH catalog_ret AS (
    SELECT
        d.d_date AS return_date,
        SUM(cr.cr_return_amt_inc_tax) AS total_amount,
        r.r_reason_desc AS reason_desc,
        'Catalog' AS return_type
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
      AND r.r_reason_desc LIKE '%Damaged%'
      AND EXISTS (
          SELECT 1
          FROM customer_address ca
          WHERE ca.ca_address_sk = cr.cr_refunded_addr_sk
            AND ca.ca_state = 'CA'
      )
    GROUP BY d.d_date, r.r_reason_desc
),
store_ret AS (
    SELECT
        d.d_date AS return_date,
        SUM(sr.sr_return_amt_inc_tax) AS total_amount,
        r.r_reason_desc AS reason_desc,
        'Store' AS return_type
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
      AND r.r_reason_desc LIKE '%Damaged%'
      AND EXISTS (
          SELECT 1
          FROM customer_address ca
          WHERE ca.ca_address_sk = sr.sr_addr_sk
            AND ca.ca_state = 'CA'
      )
    GROUP BY d.d_date, r.r_reason_desc
)
SELECT *
FROM catalog_ret
UNION ALL
SELECT *
FROM store_ret
ORDER BY return_date DESC, total_amount DESC
LIMIT 100
