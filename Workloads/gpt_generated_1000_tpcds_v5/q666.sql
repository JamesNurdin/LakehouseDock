WITH catalog_agg AS (
    SELECT
        r.r_reason_desc AS reason_desc,
        cd.cd_gender AS gender,
        SUM(cr.cr_net_loss) AS catalog_net_loss,
        COUNT(*) AS catalog_return_cnt,
        'catalog' AS source
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2450000 AND 2459999
    GROUP BY r.r_reason_desc, cd.cd_gender
),
web_agg AS (
    SELECT
        r.r_reason_desc AS reason_desc,
        cd.cd_gender AS gender,
        SUM(wr.wr_net_loss) AS web_net_loss,
        COUNT(*) AS web_return_cnt,
        'web' AS source
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE wr.wr_returned_date_sk BETWEEN 2450000 AND 2459999
    GROUP BY r.r_reason_desc, cd.cd_gender
),
combined AS (
    SELECT
        reason_desc,
        gender,
        catalog_net_loss AS net_loss,
        catalog_return_cnt AS return_cnt,
        source
    FROM catalog_agg
    UNION ALL
    SELECT
        reason_desc,
        gender,
        web_net_loss AS net_loss,
        web_return_cnt AS return_cnt,
        source
    FROM web_agg
)
SELECT
    reason_desc,
    gender,
    source,
    net_loss,
    return_cnt,
    SUM(net_loss) OVER (
        PARTITION BY reason_desc
        ORDER BY net_loss DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_net_loss
FROM combined
ORDER BY net_loss DESC, reason_desc
LIMIT 100
