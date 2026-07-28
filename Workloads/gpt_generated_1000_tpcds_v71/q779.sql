WITH
  store_ret AS (
    SELECT
      i.i_category AS category,
      d.d_year    AS year,
      d.d_month_seq AS month_seq,
      SUM(sr.sr_return_amt) AS return_amount,
      'store' AS src
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY i.i_category, d.d_year, d.d_month_seq
  ),
  catalog_ret AS (
    SELECT
      i.i_category AS category,
      d.d_year    AS year,
      d.d_month_seq AS month_seq,
      SUM(cr.cr_return_amount) AS return_amount,
      'catalog' AS src
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY i.i_category, d.d_year, d.d_month_seq
  ),
  unioned AS (
    SELECT category, year, month_seq, src, return_amount FROM store_ret
    UNION ALL
    SELECT category, year, month_seq, src, return_amount FROM catalog_ret
  )
SELECT
  u.category,
  u.year,
  u.month_seq,
  u.src,
  u.return_amount,
  ROW_NUMBER() OVER (PARTITION BY u.src ORDER BY u.return_amount DESC) AS rank_per_src
FROM unioned u
ORDER BY u.src, rank_per_src
LIMIT 100
