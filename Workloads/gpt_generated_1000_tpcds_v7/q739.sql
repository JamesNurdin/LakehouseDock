WITH sr AS (
    SELECT *
    FROM store_returns
),
cr AS (
    SELECT *
    FROM catalog_returns
)
SELECT
    d.d_year,
    ca_sr.ca_state,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_return_cnt,
    SUM(sr.sr_return_amt) AS store_return_total,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_return_cnt,
    SUM(cr.cr_return_amount) AS catalog_return_total,
    AVG(cr.cr_fee) AS avg_catalog_fee,
    MIN(sr.sr_return_amt) AS min_store_return_amt,
    MAX(cr.cr_return_amount) AS max_catalog_return_amt
FROM store_returns sr
JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
JOIN customer_address ca_sr ON sr.sr_addr_sk = ca_sr.ca_address_sk
JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
JOIN customer_address ca_cr ON cr.cr_refunded_addr_sk = ca_cr.ca_address_sk
WHERE ca_sr.ca_county = 'Richland County'
  AND ca_cr.ca_state = 'TX'
  AND d.d_year = 2001
  AND d.d_month_seq BETWEEN 1200 AND 1220
  AND cr.cr_fee > 30
GROUP BY d.d_year, ca_sr.ca_state
ORDER BY d.d_year DESC, ca_sr.ca_state
LIMIT 100
