WITH filtered_store AS (
  SELECT
    sr.sr_item_sk,
    sr.sr_customer_sk,
    sr.sr_return_amt,
    d.d_year,
    r.r_reason_desc,
    i.i_item_desc,
    i.i_brand,
    i.i_item_id,
    CASE WHEN sr.sr_return_amt > 100 THEN 'HIGH' ELSE 'NORMAL' END AS amount_category
  FROM store_returns sr
  JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  WHERE regexp_like(r.r_reason_desc, '(?i)damage|defect')
    AND i.i_item_desc LIKE '%tool%'
    AND d.d_year = 2002
    AND EXISTS (
      SELECT 1
      FROM web_returns wr
      JOIN date_dim wd ON wr.wr_returned_date_sk = wd.d_date_sk
      WHERE wd.d_year = d.d_year
        AND wr.wr_item_sk = sr.sr_item_sk
    )
),
store_item_set AS (
  SELECT DISTINCT sr_item_sk FROM filtered_store
),
web_item_set AS (
  SELECT DISTINCT wr.wr_item_sk
  FROM web_returns wr
  JOIN date_dim wd ON wr.wr_returned_date_sk = wd.d_date_sk
  WHERE wd.d_year = 2002
),
store_only_items AS (
  SELECT sr_item_sk FROM store_item_set
  EXCEPT
  SELECT wr_item_sk FROM web_item_set
)
SELECT
  f.d_year,
  i.i_item_id,
  i.i_item_desc,
  f.amount_category,
  CONCAT(i.i_brand, '-', i.i_item_id) AS brand_item,
  COUNT(DISTINCT f.sr_customer_sk) AS distinct_customers,
  SUM(DISTINCT f.sr_return_amt) AS distinct_return_amount,
  regexp_extract(i.i_item_desc, '([A-Za-z]+)') AS first_word,
  SUM(CASE WHEN f.amount_category = 'HIGH' THEN f.sr_return_amt ELSE 0 END) AS high_amount_total
FROM filtered_store f
JOIN store_only_items soi ON f.sr_item_sk = soi.sr_item_sk
JOIN item i ON f.sr_item_sk = i.i_item_sk
GROUP BY
  f.d_year,
  i.i_item_id,
  i.i_item_desc,
  f.amount_category,
  CONCAT(i.i_brand, '-', i.i_item_id),
  regexp_extract(i.i_item_desc, '([A-Za-z]+)')
HAVING COUNT(DISTINCT f.sr_customer_sk) > 5
ORDER BY f.d_year DESC, distinct_customers DESC
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY
