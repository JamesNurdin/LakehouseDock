WITH store_agg AS (
  SELECT
    d.d_date AS return_date,
    i.i_item_id,
    SUM(sr.sr_return_amt) AS store_return_amount
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  GROUP BY d.d_date, i.i_item_id
),
web_agg AS (
  SELECT
    d.d_date AS return_date,
    i.i_item_id,
    SUM(wr.wr_return_amt) AS web_return_amount
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN item i ON wr.wr_item_sk = i.i_item_sk
  GROUP BY d.d_date, i.i_item_id
),
full_agg AS (
  SELECT
    COALESCE(s.return_date, w.return_date) AS return_date,
    COALESCE(s.i_item_id, w.i_item_id) AS i_item_id,
    s.store_return_amount,
    w.web_return_amount
  FROM store_agg s
  FULL OUTER JOIN web_agg w
    ON s.return_date = w.return_date
   AND s.i_item_id = w.i_item_id
)
SELECT
  fa.return_date,
  fa.i_item_id,
  COALESCE(fa.store_return_amount, 0) AS store_return_amount,
  0 AS web_return_amount,
  (COALESCE(fa.store_return_amount, 0) + 0) AS total_return_amount,
  LAG(COALESCE(fa.store_return_amount, 0)) OVER (PARTITION BY fa.i_item_id ORDER BY fa.return_date) AS prev_return_amount,
  SUM(COALESCE(fa.store_return_amount, 0)) OVER (PARTITION BY fa.i_item_id ORDER BY fa.return_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_return_amount,
  (
    SELECT COUNT(DISTINCT sr2.sr_customer_sk)
    FROM store_returns sr2
    JOIN item i2 ON sr2.sr_item_sk = i2.i_item_sk
    JOIN date_dim d2 ON sr2.sr_returned_date_sk = d2.d_date_sk
    WHERE i2.i_item_id = fa.i_item_id
      AND d2.d_date = fa.return_date
  ) AS distinct_customers
FROM full_agg fa
WHERE fa.store_return_amount IS NOT NULL

UNION

SELECT
  fa.return_date,
  fa.i_item_id,
  0 AS store_return_amount,
  COALESCE(fa.web_return_amount, 0) AS web_return_amount,
  (0 + COALESCE(fa.web_return_amount, 0)) AS total_return_amount,
  LAG(COALESCE(fa.web_return_amount, 0)) OVER (PARTITION BY fa.i_item_id ORDER BY fa.return_date) AS prev_return_amount,
  SUM(COALESCE(fa.web_return_amount, 0)) OVER (PARTITION BY fa.i_item_id ORDER BY fa.return_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_return_amount,
  (
    SELECT COUNT(DISTINCT wr2.wr_refunded_customer_sk)
    FROM web_returns wr2
    JOIN item i2 ON wr2.wr_item_sk = i2.i_item_sk
    JOIN date_dim d2 ON wr2.wr_returned_date_sk = d2.d_date_sk
    WHERE i2.i_item_id = fa.i_item_id
      AND d2.d_date = fa.return_date
  ) AS distinct_customers
FROM full_agg fa
WHERE fa.web_return_amount IS NOT NULL

ORDER BY i_item_id, return_date
LIMIT 100
