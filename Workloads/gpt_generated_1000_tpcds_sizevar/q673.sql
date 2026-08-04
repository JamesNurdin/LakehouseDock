-- Goal: Identify high‑value web returns from 2001 that exceed the maximum store‑return amount in 2000, combine them with modest store returns from 2000, and list the address keys that appear in web returns but not in store returns and are located in California. Include, for each web‑return address, the number of prior returns.
WITH wr AS (
   SELECT
      wr.wr_returned_date_sk,
      wr.wr_returning_addr_sk,
      wr.wr_return_quantity,
      wr.wr_return_amt,
      d.d_year,
      r.r_reason_desc AS reason_desc
   FROM web_returns wr
   JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
   JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
   WHERE d.d_year = 2001
     AND wr.wr_return_amt > (
         SELECT MAX(sr2.sr_return_amt)
         FROM store_returns sr2
         JOIN date_dim d2 ON sr2.sr_returned_date_sk = d2.d_date_sk
         WHERE d2.d_year = 2000
     )
),
sr AS (
   SELECT
      sr.sr_returned_date_sk,
      sr.sr_addr_sk,
      sr.sr_return_quantity,
      sr.sr_return_amt,
      d.d_year,
      r.r_reason_desc AS reason_desc
   FROM store_returns sr
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
   WHERE d.d_year = 2000
     AND sr.sr_return_amt < 500
),
wr_counts AS (
   SELECT
      wr.wr_returning_addr_sk,
      wr.wr_return_quantity,
      lc.prior_returns
   FROM wr
   CROSS JOIN LATERAL (
      SELECT COUNT(*) AS prior_returns
      FROM web_returns wr2
      WHERE wr2.wr_returning_addr_sk = wr.wr_returning_addr_sk
        AND wr2.wr_returned_date_sk < wr.wr_returned_date_sk
   ) lc
),
combined AS (
   SELECT
      wr.wr_returning_addr_sk AS addr_sk,
      wr.reason_desc,
      wr.wr_return_amt AS return_amt,
      'web'   AS src
   FROM wr
   UNION ALL
   SELECT
      sr.sr_addr_sk AS addr_sk,
      sr.reason_desc,
      sr.sr_return_amt AS return_amt,
      'store' AS src
   FROM sr
)
SELECT
   c.addr_sk,
   c.reason_desc,
   c.return_amt,
   c.src,
   COALESCE(wc.prior_returns, 0) AS prior_returns
FROM combined c
LEFT JOIN wr_counts wc ON c.addr_sk = wc.wr_returning_addr_sk
WHERE c.addr_sk IN (
   SELECT addr_sk FROM (
      SELECT wr.wr_returning_addr_sk AS addr_sk FROM wr
      EXCEPT
      SELECT sr.sr_addr_sk FROM sr
   ) ex
   INTERSECT
   SELECT ca_address_sk FROM customer_address WHERE ca_state = 'CA'
)
ORDER BY c.return_amt DESC
LIMIT 100
