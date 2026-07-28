WITH returns_by_store AS (
  SELECT
    sr.sr_store_sk,
    s.s_store_id,
    s.s_store_name,
    SUM(sr.sr_return_amt) AS total_return_amt,
    SUM(sr.sr_store_credit) AS total_store_credit
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  WHERE sr.sr_return_amt > 0
    AND regexp_like(s.s_store_name, '\\d{3}')
    AND s.s_store_name LIKE '%Store%'
  GROUP BY sr.sr_store_sk, s.s_store_id, s.s_store_name
),
returns_dates AS (
  SELECT DISTINCT sr.sr_store_sk, sr.sr_returned_date_sk
  FROM store_returns sr
),
high_return AS (
  SELECT sr_store_sk, s_store_id, s_store_name, total_return_amt
  FROM returns_by_store
  WHERE total_return_amt > 5000
),
high_credit AS (
  SELECT sr_store_sk, s_store_id, s_store_name, total_store_credit AS total_return_amt
  FROM returns_by_store
  WHERE total_store_credit > 5000
),
combined AS (
  SELECT sr_store_sk, s_store_id, s_store_name, total_return_amt
  FROM high_return
  UNION
  SELECT sr_store_sk, s_store_id, s_store_name, total_return_amt
  FROM high_credit
),
avg_return_scalar AS (
  SELECT AVG(sr_return_amt) AS avg_return
  FROM store_returns
)
SELECT DISTINCT
  c.s_store_id,
  c.s_store_name,
  c.total_return_amt,
  a.avg_return,
  regexp_extract(c.s_store_name, '(\\d{3})', 1) AS store_code,
  CONCAT(c.s_store_name, ' - High Value') AS label
FROM combined c
CROSS JOIN avg_return_scalar a
WHERE NOT EXISTS (
  SELECT 1
  FROM promotion p
  JOIN returns_dates rd
    ON rd.sr_returned_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
  WHERE rd.sr_store_sk = c.sr_store_sk
)
ORDER BY c.total_return_amt DESC
LIMIT 100
