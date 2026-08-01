WITH
  filtered_returns AS (
    SELECT
      cr.cr_return_quantity,
      cr.cr_return_amount,
      cr.cr_ship_mode_sk,
      cr.cr_returned_date_sk,
      cr.cr_reason_sk,
      cd.cd_credit_rating,
      cd.cd_dep_employed_count,
      r.r_reason_desc
    FROM catalog_returns cr
    JOIN customer_demographics cd
      ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_return_quantity > 0
      AND cr.cr_return_amount > 10
      AND cd.cd_credit_rating IN ('Good', 'Low Risk')
      AND cd.cd_dep_employed_count >= 1
      AND cr.cr_ship_mode_sk IN (3, 5, 8, 13)
      AND cr.cr_reason_sk NOT IN (5, 9)
  ),
  agg_rollup AS (
    SELECT
      cd_credit_rating,
      cr_reason_sk,
      r_reason_desc,
      SUM(cr_return_amount) AS total_return_amount,
      COUNT(*) AS cnt
    FROM filtered_returns
    GROUP BY ROLLUP (cd_credit_rating, cr_reason_sk, r_reason_desc)
    HAVING SUM(cr_return_amount) > 100
  ),
  all_reasons AS (
    SELECT r_reason_sk, r_reason_desc FROM reason
  ),
  full_join AS (
    SELECT
      COALESCE(a.cd_credit_rating, NULL) AS cd_credit_rating,
      COALESCE(a.cr_reason_sk, ar.r_reason_sk) AS cr_reason_sk,
      COALESCE(a.r_reason_desc, ar.r_reason_desc) AS r_reason_desc,
      a.total_return_amount,
      a.cnt
    FROM agg_rollup a
    FULL OUTER JOIN all_reasons ar
      ON a.cr_reason_sk = ar.r_reason_sk
  ),
  union_agg AS (
    SELECT cr_reason_sk, cd_credit_rating, r_reason_desc, total_return_amount, cnt
    FROM full_join
    UNION DISTINCT
    SELECT cr_reason_sk, cd_credit_rating, r_reason_desc, total_return_amount, cnt
    FROM full_join
    WHERE cd_credit_rating IS NULL AND total_return_amount IS NOT NULL
  ),
  final_cte AS (
    SELECT
      ua.*, 
      ROW_NUMBER() OVER (ORDER BY ua.total_return_amount DESC) AS rn
    FROM union_agg ua
  )
SELECT DISTINCT
  f.cd_credit_rating,
  f.r_reason_desc,
  f.total_return_amount,
  f.cnt,
  f.rn,
  sm.cr_ship_mode_sk,
  (SELECT AVG(cr_return_amount) FROM catalog_returns) AS overall_avg_return_amount
FROM final_cte f
CROSS JOIN (
  SELECT DISTINCT cr_ship_mode_sk FROM catalog_returns WHERE cr_ship_mode_sk IS NOT NULL
) sm
WHERE NOT EXISTS (
  SELECT 1 FROM reason r2
  WHERE r2.r_reason_id = 'AAAAAAAAIAAAAAAA' AND r2.r_reason_sk = f.cr_reason_sk
)
ORDER BY f.total_return_amount DESC, f.rn
LIMIT 100
