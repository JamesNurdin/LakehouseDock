WITH catalog_agg AS (
  SELECT
    td.t_hour AS hour,
    SUM(cr.cr_return_amount) AS total_return_amount,
    'catalog' AS source
  FROM catalog_returns cr
  JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
  JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  WHERE cc.cc_market_manager = 'Mark Jimenez'
    AND td.t_hour BETWEEN 8 AND 20
  GROUP BY td.t_hour
),
store_agg AS (
  SELECT
    td.t_hour AS hour,
    SUM(sr.sr_return_amt) AS total_return_amount,
    'store' AS source
  FROM store_returns sr
  JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
  WHERE td.t_hour BETWEEN 8 AND 20
  GROUP BY td.t_hour
)
SELECT hour,
       total_return_amount,
       source
FROM catalog_agg
UNION ALL
SELECT hour,
       total_return_amount,
       source
FROM store_agg
ORDER BY hour, source
LIMIT 100
