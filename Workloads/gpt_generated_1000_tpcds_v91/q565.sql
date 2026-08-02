WITH
  refunded_agg AS (
    SELECT
      wr_refunded_addr_sk AS address_sk,
      COUNT(*) AS return_cnt,
      SUM(wr_return_amt) AS total_refund_amt,
      AVG(wr_return_amt_inc_tax) AS avg_refund_amt_inc_tax
    FROM web_returns
    WHERE wr_returned_date_sk BETWEEN 2451500 AND 2451900
      AND wr_return_quantity > 1
      AND wr_return_amt > 20.0
      AND wr_return_tax IS NOT NULL
    GROUP BY wr_refunded_addr_sk
  ),
  returning_agg AS (
    SELECT
      wr_returning_addr_sk AS address_sk,
      COUNT(*) AS return_cnt,
      SUM(wr_return_amt) AS total_return_amt,
      AVG(wr_return_amt_inc_tax) AS avg_return_amt_inc_tax
    FROM web_returns
    WHERE wr_returned_date_sk BETWEEN 2451500 AND 2451900
      AND wr_return_quantity > 1
      AND wr_return_amt > 20.0
      AND wr_return_tax IS NOT NULL
    GROUP BY wr_returning_addr_sk
  ),
  refunded_state AS (
    SELECT
      ca_refund.ca_state AS state,
      SUM(ra.total_refund_amt) AS state_total_refund_amt,
      SUM(ra.return_cnt) AS state_return_cnt,
      AVG(ra.avg_refund_amt_inc_tax) AS state_avg_refund_amt_inc_tax
    FROM refunded_agg ra
    JOIN customer_address ca_refund
      ON ra.address_sk = ca_refund.ca_address_sk
    WHERE ca_refund.ca_county = 'Taos County'
      AND ca_refund.ca_street_type = 'Way'
    GROUP BY ca_refund.ca_state
  ),
  returning_state AS (
    SELECT
      ca_return.ca_state AS state,
      SUM(rg.total_return_amt) AS state_total_return_amt,
      SUM(rg.return_cnt) AS state_return_cnt,
      AVG(rg.avg_return_amt_inc_tax) AS state_avg_return_amt_inc_tax
    FROM returning_agg rg
    JOIN customer_address ca_return
      ON rg.address_sk = ca_return.ca_address_sk
    WHERE ca_return.ca_county = 'Barry County'
      AND ca_return.ca_street_type = 'Boulevard'
    GROUP BY ca_return.ca_state
  )
SELECT
  state,
  state_total_refund_amt,
  state_total_return_amt,
  state_return_cnt,
  state_avg_refund_amt_inc_tax,
  state_avg_return_amt_inc_tax
FROM (
  SELECT
    state,
    state_total_refund_amt,
    NULL AS state_total_return_amt,
    state_return_cnt,
    state_avg_refund_amt_inc_tax,
    NULL AS state_avg_return_amt_inc_tax
  FROM refunded_state
  UNION ALL
  SELECT
    state,
    NULL,
    state_total_return_amt,
    state_return_cnt,
    NULL,
    state_avg_return_amt_inc_tax
  FROM returning_state
) combined
WHERE (state_total_refund_amt IS NOT NULL AND state_total_refund_amt > 1000)
   OR (state_total_return_amt IS NOT NULL AND state_total_return_amt > 1000)
ORDER BY state ASC, state_total_refund_amt DESC NULLS LAST
OFFSET 0 LIMIT 100
