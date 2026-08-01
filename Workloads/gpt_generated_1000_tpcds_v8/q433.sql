WITH base AS (
  SELECT
    sr.sr_returned_date_sk,
    sr.sr_return_time_sk,
    sr.sr_item_sk,
    sr.sr_customer_sk,
    sr.sr_return_quantity,
    sr.sr_return_amt,
    sr.sr_fee,
    sr.sr_return_tax,
    d.d_year,
    d.d_current_quarter,
    i.i_category,
    i.i_class,
    i.i_manufact_id
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 2000 AND 2002
    AND i.i_class IN ('scanners', 'furniture')
    AND sr.sr_fee > 30
),
sampled AS (
  SELECT * FROM base TABLESAMPLE BERNOULLI (10)
),
union_set AS (
  SELECT sr_returned_date_sk, sr_item_sk, sr_return_amt
  FROM sampled
  WHERE sr_return_amt > 0
  UNION
  SELECT sr_returned_date_sk, sr_item_sk, sr_return_amt
  FROM sampled
  WHERE sr_return_tax > 5
),
intersect_set AS (
  SELECT sr_item_sk FROM sampled WHERE sr_return_quantity > 1
  INTERSECT
  SELECT i_item_sk FROM item WHERE i_manufact_id IN (212, 364)
),
final AS (
  SELECT
    d_year,
    i_category,
    SUM(sr_return_amt) AS total_return_amt,
    COUNT(*) AS cnt,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY SUM(sr_return_amt) DESC) AS rn,
    (
      SELECT MAX(sr_fee)
      FROM sampled s2
      WHERE s2.d_year = base.d_year
    ) AS max_fee_year
  FROM sampled base
  WHERE d_current_quarter = 'Y'
    AND i_class = 'scanners'
    AND EXISTS (
      SELECT 1 FROM intersect_set iset WHERE iset.sr_item_sk = base.sr_item_sk
    )
  GROUP BY GROUPING SETS ((d_year, i_category), (d_year))
  HAVING SUM(sr_return_amt) > 100
)
SELECT *
FROM final
ORDER BY total_return_amt DESC
OFFSET 0 LIMIT 20
