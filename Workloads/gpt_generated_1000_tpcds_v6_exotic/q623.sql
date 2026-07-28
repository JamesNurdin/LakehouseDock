WITH catalog_agg AS (
  SELECT
    i.i_category AS category,
    td.t_hour AS hour,
    SUM(cr.cr_return_amount) AS total_return,
    CASE WHEN SUM(cr.cr_return_amount) > 500 THEN 'HIGH' ELSE 'LOW' END AS return_category,
    'catalog' AS source
  FROM catalog_returns cr
  JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  GROUP BY GROUPING SETS (
    (i.i_category, td.t_hour),
    (i.i_category),
    (td.t_hour),
    ()
  )
  HAVING SUM(cr.cr_return_amount) > 100
),
store_agg AS (
  SELECT
    i.i_category AS category,
    td.t_hour AS hour,
    SUM(sr.sr_return_amt) AS total_return,
    CASE WHEN SUM(sr.sr_return_amt) > 500 THEN 'HIGH' ELSE 'LOW' END AS return_category,
    'store' AS source
  FROM store_returns sr
  JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  GROUP BY GROUPING SETS (
    (i.i_category, td.t_hour),
    (i.i_category),
    (td.t_hour),
    ()
  )
  HAVING SUM(sr.sr_return_amt) > 100
)
SELECT *
FROM catalog_agg
UNION ALL
SELECT *
FROM store_agg
ORDER BY source, return_category DESC, total_return DESC
LIMIT 100
