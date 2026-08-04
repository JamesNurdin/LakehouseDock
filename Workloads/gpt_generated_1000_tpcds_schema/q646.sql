WITH
  avg_cat_return AS (
    SELECT avg(cr_return_amount) AS avg_amt
    FROM catalog_returns
  ),
  cat_keys AS (
    SELECT cr_item_sk
    FROM catalog_returns
  ),
  store_keys AS (
    SELECT sr_item_sk
    FROM store_returns
  ),
  cat_not_in_store AS (
    SELECT cr_item_sk
    FROM cat_keys
    EXCEPT
    SELECT sr_item_sk
    FROM store_keys
  ),
  cr_pre AS (
    SELECT
      cr.cr_returned_date_sk,
      d.d_date,
      cr.cr_item_sk,
      i.i_brand,
      cr.cr_return_amount
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
  ),
  sr_pre AS (
    SELECT
      sr.sr_returned_date_sk,
      d.d_date,
      sr.sr_item_sk,
      i.i_brand,
      sr.sr_return_amt
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
  )
SELECT
  COALESCE(cr_pre.d_date, sr_pre.d_date) AS return_date,
  COALESCE(cr_pre.cr_item_sk, sr_pre.sr_item_sk) AS item_sk,
  COALESCE(cr_pre.i_brand, sr_pre.i_brand) AS brand,
  CASE
    WHEN cr_pre.cr_return_amount IS NULL THEN sr_pre.sr_return_amt
    WHEN sr_pre.sr_return_amt IS NULL THEN cr_pre.cr_return_amount
    ELSE cr_pre.cr_return_amount + sr_pre.sr_return_amt
  END AS total_return_amount,
  CASE
    WHEN cr_pre.cr_return_amount > (SELECT avg_amt FROM avg_cat_return) THEN 'Above Avg'
    ELSE 'Below Avg'
  END AS return_category
FROM cr_pre
FULL OUTER JOIN sr_pre
  ON cr_pre.cr_item_sk = sr_pre.sr_item_sk
  AND cr_pre.d_date = sr_pre.d_date
WHERE (
        cr_pre.cr_item_sk IS NOT NULL
        OR sr_pre.sr_item_sk IS NOT NULL
      )
  AND (
        cr_pre.cr_return_amount IS NOT NULL
        OR sr_pre.sr_return_amt IS NOT NULL
      )
  AND cr_pre.cr_item_sk IN (SELECT cr_item_sk FROM cat_not_in_store)

UNION ALL

SELECT
  cr2.d_date,
  cr2.cr_item_sk,
  cr2.i_brand,
  cr2.cr_return_amount,
  'Catalog Only' AS return_category
FROM cr_pre cr2
WHERE cr2.cr_item_sk IN (SELECT cr_item_sk FROM cat_not_in_store)

LIMIT 100
