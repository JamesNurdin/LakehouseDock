WITH
  sales_by_cc AS (
    SELECT
      cc.cc_call_center_id AS cc_id,
      SUM(cs.cs_net_paid) AS total_sales,
      CASE WHEN SUM(cs.cs_net_paid) > 1000000 THEN 'HIGH' ELSE 'LOW' END AS sales_level
    FROM catalog_sales cs
    JOIN call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d
      ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY cc.cc_call_center_id
  ),

  returns_by_cc AS (
    SELECT
      cc.cc_call_center_id AS cc_id,
      SUM(cr.cr_return_amount) AS total_returns,
      CASE WHEN SUM(cr.cr_return_amount) > 500000 THEN 'HIGH' ELSE 'LOW' END AS return_level
    FROM catalog_returns cr
    JOIN call_center cc
      ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d
      ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY cc.cc_call_center_id
  ),

  full_cc AS (
    SELECT
      COALESCE(s.cc_id, r.cc_id) AS cc_id,
      s.total_sales,
      r.total_returns,
      s.sales_level,
      r.return_level
    FROM sales_by_cc s
    FULL OUTER JOIN returns_by_cc r
      ON s.cc_id = r.cc_id
  ),

  ids_2000 AS (
    SELECT cc.cc_call_center_id AS cc_id
    FROM call_center cc
    JOIN date_dim d
      ON cc.cc_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
  ),

  ids_2001 AS (
    SELECT cc.cc_call_center_id AS cc_id
    FROM call_center cc
    JOIN date_dim d
      ON cc.cc_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
  ),

  intersect_ids AS (
    SELECT cc_id FROM ids_2000
    INTERSECT
    SELECT cc_id FROM ids_2001
  )

SELECT
  f.cc_id,
  f.total_sales,
  f.total_returns,
  f.sales_level,
  f.return_level,
  (SELECT COUNT(*) FROM store s WHERE s.s_state = 'CA' AND s.s_store_name IS NOT NULL) AS ca_store_count
FROM full_cc f
WHERE f.cc_id IN (SELECT cc_id FROM intersect_ids)
UNION ALL
SELECT
  f.cc_id,
  f.total_sales,
  f.total_returns,
  f.sales_level,
  f.return_level,
  (SELECT COUNT(*) FROM store s WHERE s.s_state = 'NY' AND s.s_store_name IS NOT NULL) AS ny_store_count
FROM full_cc f
WHERE f.cc_id NOT IN (SELECT cc_id FROM intersect_ids)
ORDER BY total_sales DESC
LIMIT 100
