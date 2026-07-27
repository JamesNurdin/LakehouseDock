WITH cr_agg AS (
    SELECT
        cr.cr_call_center_sk,
        cr.cr_catalog_page_sk,
        cr.cr_reason_sk,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_return_tax,
        cr.cr_fee,
        cr.cr_return_ship_cost,
        cr.cr_net_loss
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 1000
)
SELECT
    cc.cc_name,
    cp.cp_department,
    r1.r_reason_desc AS catalog_reason_desc,
    r2.r_reason_desc AS catalog_reason_desc_dup,
    SUM(cr_agg.cr_return_amount) AS total_return_amount,
    COUNT(DISTINCT cr_agg.cr_return_quantity) AS distinct_return_qty,
    AVG(wr.wr_return_tax) AS avg_web_return_tax,
    MAX(wr.wr_net_loss) AS max_web_net_loss
FROM cr_agg
JOIN call_center cc
    ON cr_agg.cr_call_center_sk = cc.cc_call_center_sk
JOIN call_center cc_alt
    ON cr_agg.cr_call_center_sk = cc_alt.cc_call_center_sk
JOIN catalog_page cp
    ON cr_agg.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN catalog_page cp_alt
    ON cr_agg.cr_catalog_page_sk = cp_alt.cp_catalog_page_sk
JOIN reason r1
    ON cr_agg.cr_reason_sk = r1.r_reason_sk
JOIN reason r2
    ON cr_agg.cr_reason_sk = r2.r_reason_sk
JOIN web_returns wr
    ON wr.wr_reason_sk = r1.r_reason_sk
JOIN reason r3
    ON wr.wr_reason_sk = r3.r_reason_sk
JOIN reason r4
    ON wr.wr_reason_sk = r4.r_reason_sk
WHERE cc.cc_hours LIKE '8AM-%'
  AND r1.r_reason_id = 'AAAAAAAANAAAAAAA'
GROUP BY
    cc.cc_name,
    cp.cp_department,
    r1.r_reason_desc,
    r2.r_reason_desc
HAVING SUM(cr_agg.cr_return_amount) > 5000
ORDER BY total_return_amount DESC
LIMIT 100
