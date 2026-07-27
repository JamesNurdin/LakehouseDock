WITH filtered_returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_net_loss,
        cr.cr_call_center_sk,
        cr.cr_reason_sk,
        cr.cr_item_sk,
        cr.cr_refunded_cdemo_sk
    FROM catalog_returns cr
    WHERE cr.cr_net_loss > 0
)
SELECT
    cc.cc_name,
    r.r_reason_desc,
    SUM(fr.cr_net_loss) AS total_net_loss,
    COUNT(*) AS return_count,
    AVG(fr.cr_net_loss) AS avg_net_loss,
    CONCAT('CC_', CAST(cc.cc_call_center_sk AS VARCHAR)) AS cc_key
FROM filtered_returns fr
JOIN call_center cc
    ON fr.cr_call_center_sk = cc.cc_call_center_sk
JOIN item i
    ON fr.cr_item_sk = i.i_item_sk
JOIN reason r
    ON fr.cr_reason_sk = r.r_reason_sk
JOIN customer_demographics cd
    ON fr.cr_refunded_cdemo_sk = cd.cd_demo_sk
WHERE regexp_like(i.i_item_desc, '(?i)portable|wireless')
  AND r.r_reason_desc LIKE '%damage%'
  AND cd.cd_dep_employed_count >= 2
  AND cc.cc_class = 'large'
  AND fr.cr_net_loss > (SELECT AVG(cr2.cr_net_loss) FROM catalog_returns cr2)
GROUP BY
    cc.cc_name,
    r.r_reason_desc,
    cc.cc_call_center_sk
HAVING COUNT(DISTINCT i.i_item_id) > 5
ORDER BY total_net_loss DESC
LIMIT 100
