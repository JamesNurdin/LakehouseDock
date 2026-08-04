WITH base AS (
   SELECT
     cc.cc_call_center_id,
     cp.cp_catalog_page_number,
     r.r_reason_desc,
     SUM(cr.cr_return_amount) AS total_return_amount,
     SUM(cr.cr_fee) AS total_fee,
     COUNT(*) AS cnt_returns
   FROM catalog_returns cr
   JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
   JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
   WHERE cc.cc_class IN ('medium', 'large')
     AND cc.cc_mkt_id BETWEEN 2 AND 5
     AND cp.cp_catalog_page_number BETWEEN 3 AND 15
     AND r.r_reason_sk NOT IN (6, 8)
     AND cr.cr_return_amount > 10
     AND cr.cr_fee < 70
   GROUP BY cc.cc_call_center_id, cp.cp_catalog_page_number, r.r_reason_desc
),

expanded AS (
   SELECT
     b.*, cat
   FROM base b
   CROSS JOIN UNNEST(ARRAY['low', 'medium', 'high']) AS t(cat)
),

agg2 AS (
   SELECT
     cc_call_center_id,
     cat,
     AVG(total_fee) AS avg_fee,
     SUM(cnt_returns) AS total_returns
   FROM expanded
   GROUP BY cc_call_center_id, cat
),

union_ids AS (
   SELECT DISTINCT cc_call_center_id AS id FROM call_center
   UNION
   SELECT DISTINCT r_reason_id AS id FROM reason
),

intersect_ids AS (
   SELECT id FROM union_ids
   INTERSECT
   SELECT id FROM (
       SELECT cc_call_center_id AS id FROM call_center WHERE cc_call_center_id LIKE 'AAAA%'
       UNION ALL
       SELECT r_reason_id AS id FROM reason WHERE r_reason_id LIKE 'AAAA%'
   )
),

final AS (
   SELECT
     a2.cc_call_center_id,
     a2.cat,
     a2.avg_fee,
     a2.total_returns,
     COUNT(DISTINCT i.id) AS matched_id_count
   FROM agg2 a2
   LEFT JOIN intersect_ids i ON i.id = a2.cc_call_center_id
   GROUP BY a2.cc_call_center_id, a2.cat, a2.avg_fee, a2.total_returns
   HAVING a2.avg_fee > 20
)
SELECT
  cc_call_center_id,
  cat,
  avg_fee,
  total_returns,
  matched_id_count
FROM final
ORDER BY avg_fee DESC, total_returns DESC
LIMIT 100
