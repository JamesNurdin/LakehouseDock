WITH catalog_aggr AS (
    SELECT
        d.d_year AS year,
        'catalog' AS source,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE cr.cr_return_amount > 500
      AND ca.ca_state = 'CA'
    GROUP BY d.d_year
),
store_aggr AS (
    SELECT
        d.d_year AS year,
        'store' AS source,
        SUM(sr.sr_return_amt) AS total_return_amount,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE sr.sr_return_amt > 500
      AND sr.sr_customer_sk IN (
          SELECT DISTINCT sr2.sr_customer_sk
          FROM store_returns sr2
          WHERE sr2.sr_returned_date_sk = 2450815
      )
    GROUP BY d.d_year
)
SELECT year, source, total_return_amount, return_cnt
FROM catalog_aggr
UNION ALL
SELECT year, source, total_return_amount, return_cnt
FROM store_aggr
ORDER BY year DESC, total_return_amount DESC
LIMIT 100
