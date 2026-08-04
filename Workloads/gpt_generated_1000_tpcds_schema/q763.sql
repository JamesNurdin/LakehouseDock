WITH stores_matching AS (
  SELECT s.s_store_sk
  FROM store s
  WHERE s.s_street_type LIKE '%Ave%'
    AND regexp_like(s.s_street_type, '^[A-Za-z]+\\.$')
    AND concat(s.s_city, ',', s.s_state) LIKE 'San%,'
),
returns_stores AS (
  SELECT DISTINCT sr.sr_store_sk
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  WHERE d.d_year = 2000
),
stores_no_returns AS (
  SELECT sm.s_store_sk
  FROM stores_matching sm
  EXCEPT
  SELECT rs.sr_store_sk FROM returns_stores rs
),
stores_ca AS (
  SELECT s.s_store_sk
  FROM store s
  WHERE s.s_state = 'CA'
),
target_stores AS (
  SELECT s_store_sk FROM stores_no_returns
  INTERSECT
  SELECT s_store_sk FROM stores_ca
)
SELECT
  d.d_year,
  COUNT(DISTINCT sr.sr_ticket_number) AS returns_count,
  SUM(sr.sr_return_amt) AS total_return_amount,
  CASE
    WHEN SUM(sr.sr_return_amt) > 10000 THEN 'Very High'
    WHEN SUM(sr.sr_return_amt) > 5000 THEN 'High'
    ELSE 'Moderate'
  END AS return_level,
  regexp_extract(i.i_manufact, '(\\w+)$') AS manuf_suffix
FROM store_returns sr
RIGHT OUTER JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
LEFT JOIN item i ON sr.sr_item_sk = i.i_item_sk
WHERE sr.sr_store_sk IN (SELECT s_store_sk FROM target_stores)
  AND d.d_year BETWEEN 1999 AND 2001
GROUP BY d.d_year,
         i.i_manufact,
         regexp_extract(i.i_manufact, '(\\w+)$')
HAVING COUNT(*) > 0
ORDER BY d.d_year DESC
LIMIT 100
