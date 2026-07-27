WITH overall_avg AS (
    SELECT avg(cr_return_amount) AS avg_return_amount
    FROM tpcds.catalog_returns
)

SELECT
    cc.cc_call_center_id,
    cc.cc_name,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_return_quantity) AS avg_return_quantity,
    overall.avg_return_amount AS overall_avg_return_amount
FROM tpcds.catalog_returns cr
JOIN tpcds.call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
CROSS JOIN overall_avg overall
WHERE cc.cc_state = 'CA'
  AND cr.cr_return_amount > 50
GROUP BY
    cc.cc_call_center_id,
    cc.cc_name,
    overall.avg_return_amount
HAVING SUM(cr.cr_return_amount) > 1000

UNION ALL

SELECT
    cc.cc_call_center_id,
    cc.cc_name,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_return_quantity) AS avg_return_quantity,
    (SELECT avg(cr2.cr_return_amount) FROM tpcds.catalog_returns cr2) AS overall_avg_return_amount
FROM tpcds.catalog_returns cr
JOIN tpcds.call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
WHERE cc.cc_state = 'TX'
  AND cr.cr_return_amount <= 50
  AND EXISTS (
        SELECT 1
        FROM tpcds.catalog_returns cr3
        WHERE cr3.cr_returning_cdemo_sk = cr.cr_returning_cdemo_sk
          AND cr3.cr_return_amount > 200
    )
GROUP BY
    cc.cc_call_center_id,
    cc.cc_name
HAVING SUM(cr.cr_return_amount) > 500

ORDER BY total_return_amount DESC
LIMIT 100
