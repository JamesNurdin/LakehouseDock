WITH
  call_center_filtered AS (
    SELECT
      cc_call_center_sk,
      cc_manager,
      cc_market_manager,
      CONCAT(cc_manager, ' (', cc_market_manager, ')') AS manager_full,
      CASE WHEN REGEXP_LIKE(cc_manager, '^J.*') THEN 1 ELSE 0 END AS manager_starts_J
    FROM tpcds.call_center
    WHERE cc_name LIKE '%Center%'
      AND REGEXP_LIKE(cc_market_manager, 'Wolf')
  ),
  warehouse_filtered AS (
    SELECT
      w_warehouse_sk,
      w_warehouse_name,
      REGEXP_EXTRACT(w_warehouse_name, '(\\w+)', 1) AS first_word
    FROM tpcds.warehouse
    WHERE w_warehouse_name LIKE '%Local%'
       OR w_warehouse_name LIKE '%National%'
  ),
  catalog_return_agg AS (
    SELECT
      cr_warehouse_sk AS w_warehouse_sk,
      SUM(cr_return_amount) AS total_return_amount,
      COUNT(*) AS return_cnt
    FROM tpcds.catalog_returns
    GROUP BY cr_warehouse_sk
  ),
  web_sales_agg AS (
    SELECT
      ws_warehouse_sk AS w_warehouse_sk,
      SUM(ws_ext_sales_price) AS total_sales,
      COUNT(*) AS sales_cnt
    FROM tpcds.web_sales
    GROUP BY ws_warehouse_sk
  ),
  intersect_keys AS (
    SELECT cc_call_center_sk AS key_id
    FROM call_center_filtered
    INTERSECT
    SELECT w_warehouse_sk
    FROM warehouse_filtered
  ),
  except_keys AS (
    SELECT cc_call_center_sk AS key_id
    FROM call_center_filtered
    EXCEPT
    SELECT w_warehouse_sk
    FROM warehouse_filtered
  )
SELECT
  ic.key_id,
  cc.manager_full,
  wf.w_warehouse_name,
  wf.first_word,
  cr.total_return_amount,
  (
    SELECT SUM(cr2.cr_return_amount)
    FROM tpcds.catalog_returns cr2
    WHERE cr2.cr_warehouse_sk = wf.w_warehouse_sk
  ) AS correlated_return_total,
  ws.total_sales
FROM intersect_keys ic
JOIN call_center_filtered cc ON cc.cc_call_center_sk = ic.key_id
JOIN warehouse_filtered wf ON wf.w_warehouse_sk = ic.key_id
LEFT JOIN catalog_return_agg cr ON cr.w_warehouse_sk = ic.key_id
LEFT JOIN web_sales_agg ws ON ws.w_warehouse_sk = ic.key_id
WHERE cc.manager_starts_J = 1
  AND EXISTS (
    SELECT 1
    FROM tpcds.web_sales ws_inner
    WHERE ws_inner.ws_warehouse_sk = wf.w_warehouse_sk
      AND ws_inner.ws_ext_sales_price > 1000
  )
UNION DISTINCT
SELECT
  ek.key_id,
  cc.manager_full,
  wf.w_warehouse_name,
  wf.first_word,
  cr.total_return_amount,
  (
    SELECT SUM(cr2.cr_return_amount)
    FROM tpcds.catalog_returns cr2
    WHERE cr2.cr_warehouse_sk = wf.w_warehouse_sk
  ) AS correlated_return_total,
  ws.total_sales
FROM except_keys ek
JOIN call_center_filtered cc ON cc.cc_call_center_sk = ek.key_id
JOIN warehouse_filtered wf ON wf.w_warehouse_sk = ek.key_id
LEFT JOIN catalog_return_agg cr ON cr.w_warehouse_sk = ek.key_id
LEFT JOIN web_sales_agg ws ON ws.w_warehouse_sk = ek.key_id
WHERE cc.cc_manager LIKE '%Alden%'
  AND REGEXP_LIKE(wf.w_warehouse_name, '^N')
ORDER BY total_return_amount DESC NULLS LAST
LIMIT 100
