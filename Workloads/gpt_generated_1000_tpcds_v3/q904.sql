WITH catalog_returns_agg AS (
    SELECT
        'Catalog' AS return_source,
        i.i_category AS category,
        r.r_reason_desc AS reason_desc,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_count
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 9 AND 17
    GROUP BY i.i_category, r.r_reason_desc
),
web_returns_agg AS (
    SELECT
        'Web' AS return_source,
        i.i_category AS category,
        r.r_reason_desc AS reason_desc,
        SUM(wr.wr_net_loss) AS total_net_loss,
        COUNT(*) AS return_count
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 9 AND 17
    GROUP BY i.i_category, r.r_reason_desc
)
SELECT
    return_source,
    category,
    reason_desc,
    total_net_loss,
    return_count
FROM catalog_returns_agg
UNION ALL
SELECT
    return_source,
    category,
    reason_desc,
    total_net_loss,
    return_count
FROM web_returns_agg
ORDER BY total_net_loss DESC
LIMIT 100
