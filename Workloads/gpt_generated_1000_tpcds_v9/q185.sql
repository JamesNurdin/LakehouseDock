WITH combined_returns AS (
    SELECT
        'store' AS source_type,
        r.r_reason_desc AS reason_desc,
        SUM(sr.sr_return_quantity) AS total_return_quantity,
        SUM(sr.sr_net_loss) AS total_net_loss,
        CASE WHEN SUM(sr.sr_return_quantity) > 0 THEN SUM(sr.sr_net_loss) / SUM(sr.sr_return_quantity) END AS avg_net_loss_per_return,
        EXISTS (
            SELECT 1 FROM catalog_returns cr2 WHERE cr2.cr_reason_sk = r.r_reason_sk
        ) AS has_other_return
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE sr.sr_return_quantity > 5
    GROUP BY r.r_reason_desc, r.r_reason_sk

    UNION ALL

    SELECT
        'catalog' AS source_type,
        r.r_reason_desc AS reason_desc,
        SUM(cr.cr_return_quantity) AS total_return_quantity,
        SUM(cr.cr_net_loss) AS total_net_loss,
        CASE WHEN SUM(cr.cr_return_quantity) > 0 THEN SUM(cr.cr_net_loss) / SUM(cr.cr_return_quantity) END AS avg_net_loss_per_return,
        EXISTS (
            SELECT 1 FROM store_returns sr2 WHERE sr2.sr_reason_sk = r.r_reason_sk
        ) AS has_other_return
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE w.w_county = 'Marshall County'
      AND cr.cr_return_quantity > 5
      AND cc.cc_company = 1
    GROUP BY r.r_reason_desc, r.r_reason_sk
)
SELECT *
FROM combined_returns
ORDER BY total_net_loss DESC
LIMIT 100
