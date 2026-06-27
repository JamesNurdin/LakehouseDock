WITH catalog_agg AS (
    SELECT
        r.r_reason_sk,
        r.r_reason_id,
        r.r_reason_desc,
        COUNT(*) AS total_catalog_returns,
        SUM(cr.cr_return_quantity) AS total_catalog_quantity,
        SUM(cr.cr_net_loss) AS total_catalog_net_loss,
        AVG(cr.cr_return_amount) AS avg_catalog_return_amount
    FROM catalog_returns cr
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2450 AND 2456
      AND cr.cr_return_amount > 50
    GROUP BY r.r_reason_sk, r.r_reason_id, r.r_reason_desc
),
store_agg AS (
    SELECT
        r.r_reason_sk,
        r.r_reason_id,
        r.r_reason_desc,
        COUNT(*) AS total_store_returns,
        SUM(sr.sr_return_quantity) AS total_store_quantity,
        SUM(sr.sr_net_loss) AS total_store_net_loss,
        AVG(sr.sr_return_amt) AS avg_store_return_amount
    FROM store_returns sr
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    WHERE sr.sr_returned_date_sk BETWEEN 2450 AND 2456
      AND sr.sr_return_amt > 50
    GROUP BY r.r_reason_sk, r.r_reason_id, r.r_reason_desc
)
SELECT
    cat.r_reason_desc,
    cat.total_catalog_returns,
    cat.total_catalog_quantity,
    cat.total_catalog_net_loss,
    cat.avg_catalog_return_amount,
    COALESCE(store.total_store_returns, 0) AS total_store_returns,
    COALESCE(store.total_store_quantity, 0) AS total_store_quantity,
    COALESCE(store.total_store_net_loss, 0) AS total_store_net_loss,
    COALESCE(store.avg_store_return_amount, 0) AS avg_store_return_amount,
    CASE
        WHEN cat.total_catalog_net_loss = 0 THEN NULL
        ELSE COALESCE(store.total_store_net_loss, 0) / cat.total_catalog_net_loss
    END AS store_to_catalog_net_loss_ratio
FROM catalog_agg cat
LEFT JOIN store_agg store
    ON cat.r_reason_sk = store.r_reason_sk
ORDER BY cat.total_catalog_net_loss DESC
LIMIT 20
