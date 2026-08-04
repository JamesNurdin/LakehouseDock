WITH
  ship_agg AS (
    SELECT
      sm.sm_ship_mode_id,
      d.d_year,
      COALESCE(SUM(cr.cr_return_amount), 0) AS ship_return_amount,
      COUNT(cr.cr_return_quantity) AS ship_return_cnt
    FROM ship_mode sm
    FULL OUTER JOIN catalog_returns cr
      ON sm.sm_ship_mode_sk = cr.cr_ship_mode_sk
    LEFT JOIN date_dim d
      ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001 OR d.d_year IS NULL
    GROUP BY GROUPING SETS (
      (sm.sm_ship_mode_id, d.d_year),
      (sm.sm_ship_mode_id)
    )
  ),
  returns_ex AS (
    SELECT
      cc.cc_call_center_id,
      d.d_year,
      SUM(cr.cr_return_amount) AS total_return_amount,
      COUNT(*) AS num_returns
    FROM catalog_returns cr
    JOIN call_center cc
      ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d
      ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY cc.cc_call_center_id, d.d_year
    EXCEPT
    SELECT
      cc.cc_call_center_id,
      d.d_year,
      SUM(cr.cr_return_amount) AS total_return_amount,
      COUNT(*) AS num_returns
    FROM catalog_returns cr
    JOIN call_center cc
      ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d
      ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
    GROUP BY cc.cc_call_center_id, d.d_year
  )
SELECT
  re.cc_call_center_id,
  re.d_year,
  re.total_return_amount,
  re.num_returns
FROM returns_ex re
UNION ALL
SELECT
  NULL AS cc_call_center_id,
  sa.d_year,
  sa.ship_return_amount AS total_return_amount,
  sa.ship_return_cnt AS num_returns
FROM ship_agg sa
WHERE sa.ship_return_amount > 0
ORDER BY total_return_amount DESC
OFFSET 20
LIMIT 100
