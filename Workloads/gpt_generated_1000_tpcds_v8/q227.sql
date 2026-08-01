WITH filtered AS (
  SELECT
    cr.cr_call_center_sk,
    cr.cr_return_amount,
    cp.cp_catalog_page_id,
    cp.cp_type,
    cc.cc_name,
    cc.cc_city,
    cc.cc_state
  FROM catalog_returns cr
  JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
  WHERE cp.cp_type = 'monthly'
    AND regexp_like(cp.cp_catalog_page_id, '^AAAAAAA[AB]')
    AND cc.cc_name LIKE '%Center%'
),
excluded AS (
  SELECT cc_call_center_sk
  FROM call_center
  WHERE cc_state = 'CA'
  EXCEPT
  SELECT cr_call_center_sk
  FROM catalog_returns
  WHERE cr_return_amount > 5000
)
SELECT
  cc.cc_call_center_sk,
  cc.cc_name,
  concat(cc.cc_city, ', ', cc.cc_state) AS location,
  sum(f.cr_return_amount) AS total_return_amount,
  count(*) AS return_cnt,
  regexp_extract(min(f.cp_catalog_page_id), '(AAAAAAA)([AB])', 2) AS page_id_suffix,
  (
    SELECT avg(cr3.cr_return_amount)
    FROM catalog_returns cr3
    WHERE cr3.cr_call_center_sk = cc.cc_call_center_sk
  ) AS avg_return_amount_per_center
FROM filtered f
JOIN call_center cc
  ON f.cr_call_center_sk = cc.cc_call_center_sk
JOIN excluded e
  ON cc.cc_call_center_sk = e.cc_call_center_sk
GROUP BY
  cc.cc_call_center_sk,
  cc.cc_name,
  cc.cc_city,
  cc.cc_state
ORDER BY total_return_amount DESC
LIMIT 100
