WITH catalog_agg AS (
    SELECT
        cr_item_sk,
        cr_returned_time_sk,
        SUM(cr_net_loss) AS catalog_net_loss,
        COUNT(*) AS catalog_return_cnt,
        AVG(cr_fee) AS avg_catalog_fee
    FROM catalog_returns
    WHERE cr_fee > 20
    GROUP BY cr_item_sk, cr_returned_time_sk
),
store_agg AS (
    SELECT
        sr_item_sk,
        sr_return_time_sk,
        SUM(sr_net_loss) AS store_net_loss,
        COUNT(*) AS store_return_cnt,
        AVG(sr_fee) AS avg_store_fee
    FROM store_returns
    WHERE sr_fee > 20
    GROUP BY sr_item_sk, sr_return_time_sk
),
combined AS (
    SELECT
        COALESCE(ca.cr_item_sk, sa.sr_item_sk) AS item_sk,
        COALESCE(ca.cr_returned_time_sk, sa.sr_return_time_sk) AS time_sk,
        ca.catalog_net_loss,
        sa.store_net_loss,
        ca.catalog_return_cnt,
        sa.store_return_cnt
    FROM catalog_agg ca
    FULL OUTER JOIN store_agg sa
        ON ca.cr_item_sk = sa.sr_item_sk
        AND ca.cr_returned_time_sk = sa.sr_return_time_sk
)
SELECT
    td.t_hour,
    p.p_channel_tv,
    SUM(COALESCE(combined.catalog_net_loss, 0) + COALESCE(combined.store_net_loss, 0)) AS total_net_loss,
    COUNT(*) AS total_returns,
    AVG(COALESCE(combined.catalog_net_loss, 0) + COALESCE(combined.store_net_loss, 0)) AS avg_net_loss_per_return
FROM combined
JOIN time_dim td ON combined.time_sk = td.t_time_sk
JOIN promotion p ON p.p_item_sk = combined.item_sk
WHERE td.t_hour BETWEEN 10 AND 18
  AND p.p_channel_tv IS NOT NULL
GROUP BY td.t_hour, p.p_channel_tv
HAVING SUM(COALESCE(combined.catalog_net_loss, 0) + COALESCE(combined.store_net_loss, 0)) > 5000
ORDER BY total_net_loss DESC
LIMIT 20
