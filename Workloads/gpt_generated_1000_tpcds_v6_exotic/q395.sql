WITH store_agg AS (
    SELECT
        r.r_reason_desc AS reason_desc,
        SUM(sr.sr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        CASE WHEN SUM(sr.sr_net_loss) > 0 THEN 'Loss' ELSE 'Profit' END AS loss_type
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
    GROUP BY r.r_reason_desc
)
SELECT
    'store' AS source,
    s.reason_desc,
    s.total_net_loss,
    s.return_cnt,
    s.loss_type,
    (SELECT AVG(cr.cr_return_amount)
     FROM catalog_returns cr
     JOIN date_dim d2 ON cr.cr_returned_date_sk = d2.d_date_sk
     WHERE d2.d_year = 2001) AS avg_catalog_return_amount
FROM store_agg s

UNION ALL

SELECT
    'catalog' AS source,
    r.r_reason_desc AS reason_desc,
    SUM(cr.cr_net_loss) AS total_net_loss,
    COUNT(*) AS return_cnt,
    CASE WHEN SUM(cr.cr_net_loss) > 0 THEN 'Loss' ELSE 'Profit' END AS loss_type,
    CAST(NULL AS decimal(7,2)) AS avg_catalog_return_amount
FROM catalog_returns cr
JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
WHERE d.d_year = 2001
GROUP BY r.r_reason_desc
