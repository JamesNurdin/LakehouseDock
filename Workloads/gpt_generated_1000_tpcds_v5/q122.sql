WITH store_ret AS (
    SELECT
        'store_return' AS source_type,
        s.s_store_id AS entity_id,
        d.d_date AS return_date,
        SUM(sr.sr_net_loss) AS total_net_loss
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
    GROUP BY s.s_store_id, d.d_date
),
catalog_ret AS (
    SELECT
        'catalog_return' AS source_type,
        cc.cc_call_center_id AS entity_id,
        d.d_date AS return_date,
        SUM(cr.cr_net_loss) AS total_net_loss
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
    GROUP BY cc.cc_call_center_id, d.d_date
),
combined AS (
    SELECT source_type, entity_id, return_date, total_net_loss FROM store_ret
    UNION ALL
    SELECT source_type, entity_id, return_date, total_net_loss FROM catalog_ret
)
SELECT DISTINCT
    source_type,
    entity_id,
    return_date,
    total_net_loss,
    ROW_NUMBER() OVER (PARTITION BY source_type ORDER BY total_net_loss DESC) AS rn
FROM combined
ORDER BY total_net_loss DESC
LIMIT 100
