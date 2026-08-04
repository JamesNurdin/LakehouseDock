WITH returns_detail AS (
  SELECT
    sr.sr_store_sk,
    s.s_store_id,
    s.s_division_name,
    r.r_reason_desc,
    c.c_first_name,
    c.c_last_name,
    sr.sr_return_amt,
    sr.sr_reversed_charge,
    CASE WHEN sr.sr_reversed_charge > 0 THEN 'Loss' ELSE 'Gain' END AS loss_indicator
  FROM store_returns sr
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
  WHERE sr.sr_return_amt > 500
    AND r.r_reason_desc LIKE '%service%'
),
store_return_arrays AS (
  SELECT
    s.s_store_id,
    array_agg(sr.sr_return_amt) AS return_amt_arr
  FROM store s
  JOIN store_returns sr ON s.s_store_sk = sr.sr_store_sk
  GROUP BY s.s_store_id
),
unnested_returns AS (
  SELECT
    sra.s_store_id,
    amt AS return_amount
  FROM store_return_arrays sra
  CROSS JOIN UNNEST(sra.return_amt_arr) AS t(amt)
),
grouped_totals AS (
  SELECT
    s.s_division_name AS division_name,
    s.s_store_id AS store_id,
    SUM(sr.sr_return_amt) AS total_return,
    SUM(sr.sr_reversed_charge) AS total_rev,
    CASE WHEN SUM(sr.sr_reversed_charge) > 0 THEN 'Loss' ELSE 'Gain' END AS loss_indicator
  FROM store s
  JOIN store_returns sr ON s.s_store_sk = sr.sr_store_sk
  GROUP BY GROUPING SETS (
    (s.s_division_name, s.s_store_id),
    (s.s_store_id)
  )
),
union_totals AS (
  SELECT division_name, store_id, total_return
  FROM grouped_totals
  WHERE division_name = 'Unknown'
  UNION
  SELECT division_name, store_id, total_return
  FROM grouped_totals
  WHERE division_name <> 'Unknown'
),
high_rev_store AS (
  SELECT s.s_store_id AS store_id
  FROM store s
  JOIN store_returns sr ON s.s_store_sk = sr.sr_store_sk
  GROUP BY s.s_store_id
  HAVING SUM(sr.sr_reversed_charge) > 1000
),
low_rev_store AS (
  SELECT s.s_store_id AS store_id
  FROM store s
  JOIN store_returns sr ON s.s_store_sk = sr.sr_store_sk
  GROUP BY s.s_store_id
  HAVING SUM(sr.sr_reversed_charge) <= 1000
),
store_excluding_high AS (
  SELECT s.s_store_id AS store_id
  FROM store s
  EXCEPT
  SELECT store_id FROM high_rev_store
),
store_intersection AS (
  SELECT store_id FROM high_rev_store
  INTERSECT
  SELECT store_id FROM low_rev_store
)
SELECT
  u.total_return,
  u.division_name,
  u.store_id,
  ur.return_amount,
  CASE WHEN ur.return_amount > 1000 THEN 'Big' ELSE 'Small' END AS size_category
FROM union_totals u
JOIN unnested_returns ur ON u.store_id = ur.s_store_id
WHERE u.total_return IS NOT NULL
ORDER BY u.total_return DESC, u.division_name
LIMIT 100
