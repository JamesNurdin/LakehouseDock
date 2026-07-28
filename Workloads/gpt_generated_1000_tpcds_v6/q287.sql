WITH catalog_part AS (
  SELECT
    c.c_customer_sk,
    c.c_customer_id,
    cr.cr_return_amount,
    d.d_date AS return_date,
    r.r_reason_desc,
    'Catalog' AS channel
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
  JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
  WHERE d.d_year = 1998
    AND cr.cr_return_amount > 500
),
store_part AS (
  SELECT
    c.c_customer_sk,
    c.c_customer_id,
    sr.sr_return_amt,
    d.d_date AS return_date,
    r.r_reason_desc,
    'Store' AS channel
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
  JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  WHERE d.d_year = 1998
    AND sr.sr_return_amt > 500
),
combined AS (
  SELECT
    c_customer_sk,
    c_customer_id,
    cr_return_amount AS return_amount,
    return_date,
    r_reason_desc AS return_reason,
    channel
  FROM catalog_part
  UNION ALL
  SELECT
    c_customer_sk,
    c_customer_id,
    sr_return_amt AS return_amount,
    return_date,
    r_reason_desc AS return_reason,
    channel
  FROM store_part
)
SELECT
  c_customer_id,
  return_amount,
  return_date,
  return_reason,
  channel
FROM combined u
WHERE NOT EXISTS (
  SELECT 1
  FROM store_returns sr2
  JOIN date_dim d2 ON sr2.sr_returned_date_sk = d2.d_date_sk
  JOIN customer c2 ON sr2.sr_customer_sk = c2.c_customer_sk
  WHERE c2.c_customer_sk = u.c_customer_sk
    AND d2.d_date = u.return_date
)
ORDER BY return_amount DESC
LIMIT 100
