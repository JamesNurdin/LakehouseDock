WITH catalog_agg AS (
    SELECT
        r.r_reason_desc AS reason,
        'Catalog' AS channel,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        CASE WHEN SUM(cr.cr_return_quantity) > 100 THEN 'High Volume' ELSE 'Low Volume' END AS volume_category
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY r.r_reason_desc
),
web_agg AS (
    SELECT
        r.r_reason_desc AS reason,
        'Web' AS channel,
        SUM(wr.wr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        CASE WHEN SUM(wr.wr_return_quantity) > 100 THEN 'High Volume' ELSE 'Low Volume' END AS volume_category
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY r.r_reason_desc
),
combined AS (
    SELECT * FROM catalog_agg
    UNION ALL
    SELECT * FROM web_agg
)
SELECT
    c.reason,
    c.channel,
    c.total_net_loss,
    c.return_cnt,
    c.volume_category,
    (SELECT COUNT(*) FROM reason) AS total_reason_count,
    CASE WHEN EXISTS (SELECT 1 FROM store WHERE s_city = 'Spring') THEN 'Has Spring Store' ELSE 'No Spring Store' END AS spring_store_flag
FROM combined c
WHERE c.reason NOT IN (
    SELECT r2.r_reason_desc
    FROM reason r2
    WHERE r2.r_reason_sk IN (
        SELECT cr2.cr_reason_sk
        FROM catalog_returns cr2
        WHERE cr2.cr_return_quantity > 500
    )
)
ORDER BY c.total_net_loss DESC, c.reason
