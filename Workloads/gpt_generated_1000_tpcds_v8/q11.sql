WITH catalog_agg AS (
    SELECT
        r.r_reason_desc,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        'Catalog' AS return_source
    FROM catalog_returns cr
    JOIN catalog_sales cs
        ON cr.cr_order_number = cs.cs_order_number
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_return_amount > 100
    GROUP BY r.r_reason_desc
),
store_agg AS (
    SELECT
        r.r_reason_desc,
        SUM(sr.sr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        'Store' AS return_source
    FROM store_returns sr
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    WHERE sr.sr_return_amt > 100
    GROUP BY r.r_reason_desc
)
SELECT
    r_reason_desc,
    total_net_loss,
    return_cnt,
    return_source
FROM catalog_agg
UNION ALL
SELECT
    r_reason_desc,
    total_net_loss,
    return_cnt,
    return_source
FROM store_agg
ORDER BY total_net_loss DESC
LIMIT 100
