WITH store_agg AS (
    SELECT
        'store' AS source_type,
        td.t_hour,
        i.i_category,
        SUM(sr.sr_net_loss) AS total_net_loss,
        CASE WHEN SUM(sr.sr_net_loss) > 1000 THEN 'High' ELSE 'Low' END AS loss_category,
        (SELECT COUNT(DISTINCT sr2.sr_item_sk) FROM store_returns sr2) AS distinct_items_returned
    FROM store_returns sr
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE i.i_item_sk IN (
        SELECT p_item_sk FROM promotion WHERE p_purpose = 'Unknown'
    )
    GROUP BY td.t_hour, i.i_category
),
catalog_agg AS (
    SELECT
        'catalog' AS source_type,
        td.t_hour,
        i.i_category,
        SUM(cr.cr_net_loss) AS total_net_loss,
        CASE WHEN SUM(cr.cr_net_loss) > 1000 THEN 'High' ELSE 'Low' END AS loss_category,
        (SELECT COUNT(DISTINCT cr2.cr_item_sk) FROM catalog_returns cr2) AS distinct_items_returned
    FROM catalog_returns cr
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE i.i_item_sk IN (
        SELECT p_item_sk FROM promotion WHERE p_purpose = 'Unknown'
    )
    GROUP BY td.t_hour, i.i_category
)
SELECT *
FROM store_agg
UNION ALL
SELECT *
FROM catalog_agg
ORDER BY total_net_loss DESC
LIMIT 100
