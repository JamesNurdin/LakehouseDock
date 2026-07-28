WITH filtered_store AS (
    SELECT
        sr_store_sk,
        sr_return_time_sk,
        sr_return_amt,
        sr_return_quantity
    FROM store_returns
    WHERE sr_return_quantity > 1
      AND sr_return_amt > 50
)
SELECT
    ca.ca_state,
    td.t_hour,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(fs.sr_return_amt) AS avg_store_return_amt,
    COUNT(DISTINCT cr.cr_order_number) AS unique_orders,
    MIN(cr.cr_return_quantity) AS min_return_qty,
    MAX(fs.sr_return_quantity) AS max_store_return_qty
FROM catalog_returns cr
JOIN time_dim td
    ON cr.cr_returned_time_sk = td.t_time_sk
JOIN customer_address ca
    ON cr.cr_refunded_addr_sk = ca.ca_address_sk
JOIN filtered_store fs
    ON fs.sr_return_time_sk = td.t_time_sk
WHERE td.t_am_pm = 'PM'
  AND td.t_minute IN (5, 9, 14)
  AND cr.cr_return_amt_inc_tax > 100
  AND ca.ca_state = 'CA'
  AND cr.cr_returning_addr_sk = 3021775
  AND EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_store_sk = fs.sr_store_sk
          AND sr2.sr_return_quantity > 5
        GROUP BY sr2.sr_store_sk
        HAVING COUNT(*) > 10
      )
GROUP BY GROUPING SETS (
    (ca.ca_state, td.t_hour),
    (ca.ca_state),
    (td.t_hour),
    ()
)
ORDER BY total_return_amount DESC
LIMIT 100
