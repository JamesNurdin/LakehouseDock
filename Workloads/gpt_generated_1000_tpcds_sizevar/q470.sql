WITH
  item_sales AS (
    SELECT
      i.i_item_sk,
      i.i_item_id,
      i.i_item_desc,
      regexp_extract(i.i_item_desc, '(\\w+)', 1) AS first_word,
      SUM(cs.cs_net_paid) AS total_net_paid,
      COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY i.i_item_sk, i.i_item_id, i.i_item_desc, regexp_extract(i.i_item_desc, '(\\w+)', 1)
  ),
  store_sales_agg AS (
    SELECT
      ss.ss_item_sk,
      SUM(ss.ss_net_paid) AS store_total_paid,
      COUNT(*) AS store_txn
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY ss.ss_item_sk
  ),
  store_returns_agg AS (
    SELECT
      sr.sr_item_sk,
      SUM(sr.sr_return_amt) AS return_total_amt,
      COUNT(*) AS return_txn
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY sr.sr_item_sk
  ),
  cross_set AS (
    SELECT 1 AS grp UNION ALL SELECT 2 UNION ALL SELECT 3
  ),
  date_small AS (
    SELECT d.d_date_sk, d.d_date
    FROM date_dim d
    WHERE d.d_year = 2001 AND d.d_month_seq BETWEEN 1 AND 2
  )
SELECT
  COALESCE(ssa.ss_item_sk, sra.sr_item_sk) AS item_sk,
  COALESCE(i.i_item_id, 'UNKNOWN') AS item_id,
  COALESCE(i.i_item_desc, 'No Desc') AS item_desc,
  isales.first_word,
  isales.total_net_paid,
  ssa.store_total_paid,
  sra.return_total_amt,
  ds.d_date,
  cs.grp,
  CASE
    WHEN i.i_item_desc LIKE '%RED%' THEN 'RED'
    WHEN i.i_item_desc LIKE '%BLUE%' THEN 'BLUE'
    ELSE 'OTHER'
  END AS color_category
FROM store_sales_agg ssa
FULL OUTER JOIN store_returns_agg sra
  ON ssa.ss_item_sk = sra.sr_item_sk
LEFT JOIN item i
  ON i.i_item_sk = COALESCE(ssa.ss_item_sk, sra.sr_item_sk)
LEFT JOIN item_sales isales
  ON isales.i_item_sk = i.i_item_sk
CROSS JOIN cross_set cs
CROSS JOIN date_small ds
WHERE regexp_like(isales.first_word, '^[A-Z]{3}$')
ORDER BY item_sk NULLS LAST, ds.d_date DESC, cs.grp
LIMIT 100
