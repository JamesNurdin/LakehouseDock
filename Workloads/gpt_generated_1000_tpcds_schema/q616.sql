WITH
  sampled_store AS (
    SELECT *
    FROM store
    TABLESAMPLE BERNOULLI (10)
  ),
  sr_pre AS (
    SELECT
      s.s_store_sk AS key_id,
      d.d_year,
      SUM(sr.sr_return_amt) AS total_amount,
      COUNT(*) AS cnt,
      CASE WHEN SUM(sr.sr_return_amt) > 1000 THEN 'HIGH' ELSE 'LOW' END AS category
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN sampled_store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE t.t_sub_shift = 'morning'
    GROUP BY s.s_store_sk, d.d_year
  ),
  cr_pre AS (
    SELECT
      cr.cr_reason_sk AS key_id,
      d2.d_year,
      SUM(cr.cr_return_amount) AS total_amount,
      COUNT(*) AS cnt,
      CASE WHEN SUM(cr.cr_return_amount) > 2000 THEN 'HIGH' ELSE 'LOW' END AS category
    FROM catalog_returns cr
    JOIN date_dim d2 ON cr.cr_returned_date_sk = d2.d_date_sk
    JOIN time_dim t2 ON cr.cr_returned_time_sk = t2.t_time_sk
    JOIN reason r2 ON cr.cr_reason_sk = r2.r_reason_sk
    JOIN customer c_ref ON cr.cr_refunded_customer_sk = c_ref.c_customer_sk
    JOIN customer c_ret ON cr.cr_returning_customer_sk = c_ret.c_customer_sk
    WHERE r2.r_reason_desc LIKE '%size%'
    GROUP BY cr.cr_reason_sk, d2.d_year
  ),
  union_all AS (
    SELECT * FROM sr_pre
    UNION DISTINCT
    SELECT * FROM cr_pre
  ),
  intersect_keys AS (
    SELECT key_id FROM sr_pre
    INTERSECT
    SELECT key_id FROM cr_pre
  ),
  filtered AS (
    SELECT u.*
    FROM union_all u
    WHERE u.key_id IN (SELECT key_id FROM intersect_keys)
      AND NOT EXISTS (
        SELECT 1
        FROM store s2
        WHERE s2.s_store_sk = u.key_id
          AND s2.s_state = 'NY'
      )
  )
SELECT
  f.key_id,
  f.d_year,
  f.total_amount,
  f.cnt,
  f.category
FROM filtered f
ORDER BY f.total_amount DESC
OFFSET 0
FETCH FIRST 100 ROWS ONLY
