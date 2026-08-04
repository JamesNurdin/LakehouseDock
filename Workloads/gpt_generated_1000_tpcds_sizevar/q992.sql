WITH sampled_cr AS (
  SELECT *
  FROM catalog_returns TABLESAMPLE BERNOULLI (10)
),

filtered_cr AS (
  SELECT cr.*, cp.cp_description, cp.cp_type
  FROM sampled_cr cr
  JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  WHERE regexp_like(cp.cp_description, '(?i)promo')
),

aggregated AS (
  SELECT cc.cc_call_center_sk,
         cc.cc_name,
         SUM(fr.cr_return_amount) AS total_return_amount,
         COUNT(*) AS return_cnt,
         CONCAT('Center: ', cc.cc_name) AS center_label,
         SUBSTRING(cc.cc_name, 1, 5) AS name_prefix
  FROM filtered_cr fr
  RIGHT OUTER JOIN call_center cc
    ON fr.cr_call_center_sk = cc.cc_call_center_sk
  GROUP BY cc.cc_call_center_sk, cc.cc_name
),

call_center_ids_all AS (
  SELECT cc_call_center_sk FROM call_center
),

call_center_ids_with_returns AS (
  SELECT DISTINCT cr_call_center_sk FROM catalog_returns
),

ids_without_returns AS (
  SELECT cc_call_center_sk FROM call_center_ids_all
  EXCEPT
  SELECT cr_call_center_sk FROM call_center_ids_with_returns
),

ids_with_pattern AS (
  SELECT cc.cc_call_center_sk
  FROM call_center cc
  WHERE cc.cc_name LIKE '%Center%'
),

intersected_ids AS (
  SELECT cc_call_center_sk FROM ids_without_returns
  INTERSECT
  SELECT cc_call_center_sk FROM ids_with_pattern
)

SELECT a.cc_call_center_sk,
       a.cc_name,
       a.total_return_amount,
       a.return_cnt,
       a.center_label,
       a.name_prefix,
       (SELECT AVG(cr_return_amount)
        FROM catalog_returns cr2
        WHERE cr2.cr_call_center_sk = a.cc_call_center_sk) AS avg_return_amount,
       CASE WHEN a.cc_call_center_sk IN (SELECT cc_call_center_sk FROM intersected_ids)
            THEN 'NoReturnAndPattern'
            ELSE 'Other'
       END AS category
FROM aggregated a
WHERE a.cc_name LIKE '%Call%'
ORDER BY a.total_return_amount DESC
LIMIT 100
