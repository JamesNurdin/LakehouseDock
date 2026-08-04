WITH
  sample_returns AS (
    SELECT *
    FROM catalog_returns
    TABLESAMPLE BERNOULLI (10)
  ),
  agg_by_reason_ship AS (
    SELECT
      cr_reason_sk,
      cr_ship_mode_sk,
      SUM(cr_return_amt_inc_tax) AS total_return_inc_tax,
      COUNT(*) AS cnt_returns,
      SUM(CASE WHEN cr_return_amt_inc_tax > 5000 THEN 1 ELSE 0 END) AS high_amount_cnt
    FROM sample_returns
    GROUP BY cr_reason_sk, cr_ship_mode_sk
  ),
  reason_join AS (
    SELECT
      a.cr_reason_sk,
      a.cr_ship_mode_sk,
      a.total_return_inc_tax,
      a.cnt_returns,
      a.high_amount_cnt,
      r.r_reason_desc
    FROM agg_by_reason_ship a
    JOIN reason r
      ON a.cr_reason_sk = r.r_reason_sk
  ),
  ship_join AS (
    SELECT
      a.cr_reason_sk,
      a.cr_ship_mode_sk,
      a.total_return_inc_tax,
      a.cnt_returns,
      a.high_amount_cnt,
      s.sm_type,
      s.sm_contract
    FROM agg_by_reason_ship a
    JOIN ship_mode s
      ON a.cr_ship_mode_sk = s.sm_ship_mode_sk
  ),
  full_combined AS (
    SELECT
      COALESCE(rj.cr_reason_sk, sj.cr_reason_sk) AS cr_reason_sk,
      COALESCE(rj.cr_ship_mode_sk, sj.cr_ship_mode_sk) AS cr_ship_mode_sk,
      COALESCE(rj.total_return_inc_tax, 0) + COALESCE(sj.total_return_inc_tax, 0) AS total_return_inc_tax,
      COALESCE(rj.cnt_returns, 0) + COALESCE(sj.cnt_returns, 0) AS cnt_returns,
      COALESCE(rj.high_amount_cnt, 0) + COALESCE(sj.high_amount_cnt, 0) AS high_amount_cnt,
      rj.r_reason_desc,
      sj.sm_type,
      sj.sm_contract
    FROM reason_join rj
    FULL OUTER JOIN ship_join sj
      ON rj.cr_reason_sk = sj.cr_reason_sk
         AND rj.cr_ship_mode_sk = sj.cr_ship_mode_sk
  ),
  filtered AS (
    SELECT *
    FROM full_combined fc
    WHERE fc.total_return_inc_tax > 1000
      AND fc.cnt_returns >= 5
      AND (fc.sm_contract LIKE 'P%' OR fc.sm_contract LIKE 'A%')
      AND fc.r_reason_desc NOT LIKE '%duplicate%'
      AND fc.r_reason_desc IS NOT NULL
      AND NOT EXISTS (
        SELECT 1
        FROM reason r2
        WHERE r2.r_reason_sk = fc.cr_reason_sk
          AND r2.r_reason_desc LIKE '%duplicate%'
      )
  ),
  intersect_keys AS (
    SELECT cr_reason_sk FROM catalog_returns WHERE cr_return_amount > 1000
    INTERSECT
    SELECT cr_reason_sk FROM catalog_returns WHERE cr_return_ship_cost > 500
  ),
  final AS (
    SELECT
      f.cr_reason_sk,
      f.r_reason_desc,
      f.sm_type,
      f.sm_contract,
      f.total_return_inc_tax,
      f.cnt_returns,
      f.high_amount_cnt,
      CASE
        WHEN f.high_amount_cnt > 0 THEN 'HAS_HIGH'
        ELSE 'NO_HIGH'
      END AS high_flag
    FROM filtered f
    JOIN intersect_keys ik
      ON f.cr_reason_sk = ik.cr_reason_sk
  )
SELECT *
FROM final
ORDER BY total_return_inc_tax DESC
LIMIT 100
