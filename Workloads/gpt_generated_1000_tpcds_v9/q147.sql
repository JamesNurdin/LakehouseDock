WITH intersect_reasons AS (
    SELECT cr_reason_sk AS reason_sk
    FROM catalog_returns
    INTERSECT
    SELECT wr_reason_sk AS reason_sk
    FROM web_returns
),

filtered_reasons AS (
    SELECT r.r_reason_sk,
           r.r_reason_desc,
           CASE
               WHEN regexp_like(r.r_reason_desc, 'price') THEN 'PriceRelated'
               WHEN regexp_like(r.r_reason_desc, 'service') THEN 'ServiceRelated'
               ELSE 'Other'
           END AS reason_category
    FROM reason r
    WHERE r.r_reason_sk IN (SELECT reason_sk FROM intersect_reasons)
      AND (r.r_reason_desc LIKE '%price%' OR r.r_reason_desc LIKE '%service%')
),

call_center_cats AS (
    SELECT cc.cc_call_center_sk,
           cc.cc_name,
           cc.cc_city,
           cc.cc_state,
           CASE
               WHEN regexp_like(cc.cc_name, '^Center') THEN 'StartsWithCenter'
               WHEN regexp_like(cc.cc_name, 'Center$') THEN 'EndsWithCenter'
               ELSE 'ContainsCenter'
           END AS name_category
    FROM call_center cc
    WHERE cc.cc_name LIKE '%Center%'
),

catalog_agg AS (
    SELECT cr.cr_call_center_sk AS cc_sk,
           cr.cr_reason_sk AS reason_sk,
           SUM(cr.cr_net_loss) AS catalog_net_loss,
           dd.d_year AS year
    FROM catalog_returns cr
    JOIN date_dim dd ON cr.cr_returned_date_sk = dd.d_date_sk
    GROUP BY cr.cr_call_center_sk, cr.cr_reason_sk, dd.d_year
),

web_agg AS (
    SELECT wr.wr_reason_sk AS reason_sk,
           SUM(wr.wr_net_loss) AS web_net_loss,
           dd.d_year AS year
    FROM web_returns wr
    JOIN date_dim dd ON wr.wr_returned_date_sk = dd.d_date_sk
    GROUP BY wr.wr_reason_sk, dd.d_year
)

SELECT
    cc.cc_call_center_sk,
    cc.cc_name,
    SUBSTRING(cc.cc_name FROM 1 FOR 10) AS name_prefix,
    CONCAT(cc.cc_city, '-', cc.cc_state) AS location_code,
    cc.cc_city,
    cc.cc_state,
    cc.name_category,
    rf.r_reason_desc,
    SUBSTRING(rf.r_reason_desc FROM 1 FOR 30) AS reason_snippet,
    regexp_extract(rf.r_reason_desc, '([A-Za-z]+)') AS first_word_reason,
    rf.reason_category,
    ca.year,
    ca.catalog_net_loss,
    COALESCE(wa.web_net_loss, 0) AS web_net_loss,
    (ca.catalog_net_loss + COALESCE(wa.web_net_loss, 0)) AS total_net_loss,
    CASE
        WHEN (ca.catalog_net_loss + COALESCE(wa.web_net_loss, 0)) < 0 THEN 'Loss'
        WHEN (ca.catalog_net_loss + COALESCE(wa.web_net_loss, 0)) = 0 THEN 'BreakEven'
        ELSE 'Profit'
    END AS net_loss_bucket,
    (SELECT AVG(cr2.cr_net_loss)
     FROM catalog_returns cr2
     WHERE cr2.cr_reason_sk = rf.r_reason_sk) AS avg_reason_net_loss
FROM call_center_cats cc
JOIN catalog_agg ca ON cc.cc_call_center_sk = ca.cc_sk
JOIN filtered_reasons rf ON ca.reason_sk = rf.r_reason_sk
LEFT JOIN web_agg wa ON wa.reason_sk = rf.r_reason_sk AND wa.year = ca.year
WHERE NOT EXISTS (
    SELECT 1
    FROM catalog_returns cr_ex
    WHERE cr_ex.cr_call_center_sk = cc.cc_call_center_sk
      AND cr_ex.cr_net_loss > 1000
)
ORDER BY total_net_loss DESC, cc.cc_call_center_sk
LIMIT 100
