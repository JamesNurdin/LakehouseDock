WITH
  sr_sample AS (
    SELECT *
    FROM store_returns
    TABLESAMPLE BERNOULLI (10)
  ),
  full_data AS (
    SELECT
      COALESCE(sr.sr_store_sk, s.s_store_sk) AS store_sk,
      s.s_store_name,
      s.s_city,
      sr.sr_return_amt_inc_tax,
      sr.sr_return_quantity,
      sr.sr_item_sk,
      d.d_year
    FROM sr_sample sr
    FULL OUTER JOIN store s
      ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN date_dim d
      ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE (s.s_store_name IS NOT NULL AND regexp_like(s.s_store_name, '^Park'))
       OR sr.sr_store_sk IS NOT NULL
  ),
  joined_items AS (
    SELECT
      fd.store_sk,
      fd.s_store_name,
      fd.s_city,
      i.i_brand,
      fd.sr_return_amt_inc_tax,
      fd.sr_return_quantity,
      fd.d_year
    FROM full_data fd
    LEFT JOIN item i
      ON fd.sr_item_sk = i.i_item_sk
    WHERE i.i_brand LIKE 'B%'
  )
SELECT
  CONCAT(j.s_store_name, ' - ', j.s_city) AS store_full_name,
  j.i_brand,
  COUNT(*) AS return_rows,
  SUM(COALESCE(j.sr_return_amt_inc_tax, 0)) AS total_return_amount,
  AVG(COALESCE(j.sr_return_amt_inc_tax, 0)) AS avg_return_amount,
  SUM(COALESCE(j.sr_return_quantity, 0)) AS total_quantity
FROM joined_items j
WHERE j.d_year = 2001
GROUP BY CONCAT(j.s_store_name, ' - ', j.s_city), j.i_brand
ORDER BY total_return_amount DESC
LIMIT 100
