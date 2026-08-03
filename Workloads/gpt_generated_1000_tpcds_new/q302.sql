WITH sampled_cc AS (
    SELECT *
    FROM call_center
    TABLESAMPLE BERNOULLI (5)
),
returns_filtered AS (
    SELECT cr.cr_call_center_sk,
           cr.cr_return_amount,
           r.r_reason_desc
    FROM catalog_returns cr
    JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    WHERE regexp_like(r.r_reason_desc, '(?i)customer')
)
SELECT
    cc.cc_call_center_sk,
    cc.cc_name,
    concat(cc.cc_city, ', ', cc.cc_state) AS location,
    SUM(rf.cr_return_amount) AS total_return,
    regexp_extract(cc.cc_name, '(\\w+)$') AS name_suffix
FROM sampled_cc cc
JOIN returns_filtered rf
  ON rf.cr_call_center_sk = cc.cc_call_center_sk
WHERE cc.cc_name LIKE '%Center%'
  AND concat(cc.cc_city, ', ', cc.cc_state) LIKE 'A%_%'
GROUP BY
    cc.cc_call_center_sk,
    cc.cc_name,
    concat(cc.cc_city, ', ', cc.cc_state),
    regexp_extract(cc.cc_name, '(\\w+)$')
HAVING SUM(rf.cr_return_amount) > 500
EXCEPT
SELECT
    cc2.cc_call_center_sk,
    cc2.cc_name,
    concat(cc2.cc_city, ', ', cc2.cc_state) AS location,
    CAST(0 AS decimal(7,2)) AS total_return,
    regexp_extract(cc2.cc_name, '(\\w+)$') AS name_suffix
FROM sampled_cc cc2
WHERE cc2.cc_employees < 50
ORDER BY total_return DESC
LIMIT 100
