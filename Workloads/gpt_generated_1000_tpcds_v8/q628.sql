WITH
  sr AS (
    SELECT
      s.s_store_id AS dim_key,
      r.r_reason_desc AS reason,
      SUM(sr.sr_return_amt_inc_tax) AS total_return
    FROM store_returns sr
    RIGHT OUTER JOIN store s
      ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN reason r
      ON sr.sr_reason_sk = r.r_reason_sk
    WHERE s.s_state = 'CA'
    GROUP BY CUBE (s.s_store_id, r.r_reason_desc)
  ),
  cr AS (
    SELECT
      i.i_category AS dim_key,
      r.r_reason_desc AS reason,
      SUM(cr.cr_return_amount) AS total_return
    FROM catalog_returns cr
    JOIN catalog_sales cs
      ON cr.cr_order_number = cs.cs_order_number
    JOIN item i
      ON cr.cr_item_sk = i.i_item_sk
    LEFT JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    WHERE i.i_brand_id = 12
    GROUP BY CUBE (i.i_category, r.r_reason_desc)
  ),
  union_all AS (
    SELECT dim_key, reason, total_return FROM sr
    UNION ALL
    SELECT dim_key, reason, total_return FROM cr
  ),
  distinct_reasons AS (
    SELECT DISTINCT reason FROM union_all
  ),
  common_reasons AS (
    SELECT reason FROM distinct_reasons
    INTERSECT
    SELECT r_reason_desc FROM reason
  ),
  final AS (
    SELECT
      dr.reason,
      lt.cnt_lateral AS return_count,
      (
        SELECT SUM(total_return)
        FROM union_all ua
        WHERE ua.reason = dr.reason
      ) AS total_return_amount
    FROM common_reasons dr
    CROSS JOIN LATERAL (
      SELECT COUNT(*) AS cnt_lateral
      FROM union_all ua
      WHERE ua.reason = dr.reason
    ) lt
  )
SELECT
  reason,
  return_count,
  total_return_amount
FROM final
WHERE reason IS NOT NULL
LIMIT 100
