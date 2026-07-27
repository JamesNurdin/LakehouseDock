WITH center_stats AS (
    SELECT
        cr.cr_call_center_sk,
        cc.cc_state,
        cc.cc_city,
        AVG(cr.cr_return_amount) AS avg_return_amount,
        SUM(cr.cr_return_quantity) AS total_quantity,
        ROW_NUMBER() OVER (PARTITION BY cc.cc_state ORDER BY AVG(cr.cr_return_amount) DESC) AS rn_state
    FROM catalog_returns cr
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    GROUP BY cr.cr_call_center_sk, cc.cc_state, cc.cc_city
)
SELECT
    cs.cr_call_center_sk,
    cs.cc_state,
    cs.cc_city,
    cs.avg_return_amount,
    cs.total_quantity,
    cs.rn_state,
    (SELECT AVG(cr_all.cr_return_amount) FROM catalog_returns cr_all) AS overall_avg_return
FROM center_stats cs
JOIN call_center cc
    ON cs.cr_call_center_sk = cc.cc_call_center_sk
WHERE cs.rn_state <= 3
  AND cs.avg_return_amount > 1500
  AND cc.cc_mkt_id IN (1, 5)
  AND EXISTS (
        SELECT 1
        FROM catalog_returns cr_check
        WHERE cr_check.cr_call_center_sk = cs.cr_call_center_sk
          AND cr_check.cr_return_amount > 2000
    )
UNION ALL
SELECT
    cs2.cr_call_center_sk,
    cs2.cc_state,
    cs2.cc_city,
    cs2.avg_return_amount,
    cs2.total_quantity,
    cs2.rn_state,
    (SELECT AVG(cr_all2.cr_return_amount) FROM catalog_returns cr_all2) AS overall_avg_return
FROM center_stats cs2
JOIN call_center cc2
    ON cs2.cr_call_center_sk = cc2.cc_call_center_sk
WHERE cs2.rn_state > 3
  AND cs2.avg_return_amount <= 1500
  AND cc2.cc_mkt_id IN (2, 3)
  AND EXISTS (
        SELECT 1
        FROM catalog_returns cr_check2
        WHERE cr_check2.cr_call_center_sk = cs2.cr_call_center_sk
          AND cr_check2.cr_return_amount <= 500
    )
LIMIT 100
