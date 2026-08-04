WITH
  store_ret_agg AS (
    SELECT
      sr.sr_return_time_sk AS time_sk,
      SUM(sr.sr_return_amt) AS total_store_return,
      COUNT(*) AS cnt_store_returns,
      CASE WHEN SUM(sr.sr_return_amt) > 10000 THEN 'HIGH' ELSE 'LOW' END AS store_level
    FROM store_returns sr
    GROUP BY sr.sr_return_time_sk
  ),
  catalog_ret_agg AS (
    SELECT
      cr.cr_returned_time_sk AS time_sk,
      SUM(cr.cr_return_amount) AS total_catalog_return,
      COUNT(*) AS cnt_catalog_returns,
      CASE WHEN SUM(cr.cr_return_amount) > 5000 THEN 'HIGH' ELSE 'LOW' END AS catalog_level
    FROM catalog_returns cr
    GROUP BY cr.cr_returned_time_sk
  ),
  full_join AS (
    SELECT
      COALESCE(s.time_sk, c.time_sk) AS time_sk,
      s.total_store_return,
      c.total_catalog_return,
      s.store_level,
      c.catalog_level
    FROM store_ret_agg s
    FULL OUTER JOIN catalog_ret_agg c
      ON s.time_sk = c.time_sk
  ),
  union_data AS (
    SELECT
      wp.wp_web_page_id AS id,
      regexp_extract(wp.wp_url, 'https?://([^/]+)', 1) AS key_text,
      CASE WHEN wp.wp_char_count > 3000 THEN 'LONG' ELSE 'SHORT' END AS size_flag
    FROM web_page wp
    WHERE wp.wp_url LIKE '%foo%'
    UNION
    SELECT
      cp.cp_catalog_page_id AS id,
      substring(cp.cp_description, 1, 20) AS key_text,
      CASE WHEN regexp_like(cp.cp_description, '(?i)sale') THEN 'SALE' ELSE 'OTHER' END AS size_flag
    FROM catalog_page cp
    WHERE cp.cp_description LIKE '%sale%'
  ),
  intersect_customers AS (
    SELECT sr_customer_sk AS cust_sk FROM (
      SELECT DISTINCT sr.sr_customer_sk AS sr_customer_sk FROM store_returns sr
    )
    INTERSECT
    SELECT cr_returning_customer_sk FROM (
      SELECT DISTINCT cr.cr_returning_customer_sk FROM catalog_returns cr
    )
  )
SELECT
  fj.time_sk,
  fj.total_store_return,
  fj.total_catalog_return,
  fj.store_level,
  fj.catalog_level,
  uc.id,
  uc.key_text,
  uc.size_flag,
  (uc.id || '_' || uc.size_flag) AS composite_id,
  CASE WHEN ic.cust_sk IS NOT NULL THEN 'BOTH_RETURNS' ELSE 'NO_MATCH' END AS return_flag
FROM full_join fj
FULL OUTER JOIN union_data uc
  ON fj.time_sk = TRY_CAST(substr(uc.id, 1, 5) AS integer)
LEFT JOIN intersect_customers ic
  ON ic.cust_sk = fj.time_sk
ORDER BY fj.time_sk DESC
LIMIT 100
