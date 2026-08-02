WITH date_filter AS (
    SELECT d_date_sk
    FROM date_dim
    WHERE d_year = 2001
)
SELECT
    COALESCE(u.return_channel, 'ALL') AS return_channel,
    COALESCE(u.reason_desc, 'ALL')   AS reason_desc,
    SUM(u.total_return_amount)      AS total_return_amount,
    SUM(u.total_return_qty)         AS total_return_qty,
    SUM(u.total_net_loss)           AS total_net_loss,
    SUM(u.return_rows)              AS return_rows,
    CASE WHEN SUM(u.total_net_loss) > 10000 THEN 'High' ELSE 'Low' END AS loss_category,
    (SELECT MAX(d_month_seq) FROM date_dim WHERE d_year = 2001) AS max_month_seq,
    CASE WHEN SUM(u.total_return_amount) > 50000 THEN 'High Return' ELSE 'Low Return' END AS return_level
FROM (
    SELECT
        'Catalog' AS return_channel,
        r.r_reason_desc AS reason_desc,
        SUM(cr.cr_return_amount)   AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_return_qty,
        SUM(cr.cr_net_loss)        AS total_net_loss,
        COUNT(*)                   AS return_rows
    FROM catalog_returns cr
    JOIN date_filter d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    CROSS JOIN LATERAL (
        SELECT cc.cc_manager
        FROM call_center cc
        WHERE cc.cc_call_center_sk = cr.cr_call_center_sk
        LIMIT 1
    ) AS cc_l (manager)
    GROUP BY r.r_reason_desc
    UNION ALL
    SELECT
        'Store' AS return_channel,
        r.r_reason_desc AS reason_desc,
        SUM(sr.sr_return_amt)      AS total_return_amount,
        SUM(sr.sr_return_quantity) AS total_return_qty,
        SUM(sr.sr_net_loss)        AS total_net_loss,
        COUNT(*)                   AS return_rows
    FROM store_returns sr
    JOIN date_filter d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    CROSS JOIN LATERAL (
        SELECT s.s_manager
        FROM store s
        WHERE s.s_store_sk = sr.sr_store_sk
        LIMIT 1
    ) AS s_l (manager)
    GROUP BY r.r_reason_desc
) u
GROUP BY ROLLUP(u.return_channel, u.reason_desc)
ORDER BY
    CASE WHEN COALESCE(u.return_channel, 'ALL') = 'Catalog' THEN 1
         WHEN COALESCE(u.return_channel, 'ALL') = 'Store' THEN 2
         ELSE 3 END,
    COALESCE(u.reason_desc, 'ALL')
LIMIT 100
