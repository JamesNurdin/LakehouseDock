WITH catalog_agg AS (
  SELECT
    'Catalog' AS source_type,
    d.d_year AS year,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_return_quantity) AS avg_return_quantity,
    CASE WHEN SUM(cr.cr_return_amount) > 5000 THEN 'High' ELSE 'Low' END AS return_category
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
  JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  WHERE d.d_year = 2001
    AND cc.cc_state = 'CA'
    AND EXISTS (
      SELECT 1 FROM promotion p2
      WHERE p2.p_start_date_sk = d.d_date_sk
        AND p2.p_channel_tv = 'Y'
    )
  GROUP BY d.d_year
),
web_agg AS (
  SELECT
    'Web' AS source_type,
    d.d_year AS year,
    SUM(wr.wr_return_amt) AS total_return_amount,
    AVG(wr.wr_return_quantity) AS avg_return_quantity,
    CASE WHEN SUM(wr.wr_return_amt) > 5000 THEN 'High' ELSE 'Low' END AS return_category
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
  WHERE d.d_year = 2001
    AND EXISTS (
      SELECT 1 FROM promotion p2
      WHERE p2.p_start_date_sk = d.d_date_sk
        AND p2.p_channel_tv = 'Y'
    )
  GROUP BY d.d_year
)
SELECT
  source_type,
  year,
  total_return_amount,
  avg_return_quantity,
  return_category
FROM catalog_agg
UNION ALL
SELECT
  source_type,
  year,
  total_return_amount,
  avg_return_quantity,
  return_category
FROM web_agg
ORDER BY year, source_type
LIMIT 100
