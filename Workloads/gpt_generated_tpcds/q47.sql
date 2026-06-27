WITH catalog_agg AS (
    SELECT
        cr_reason_sk,
        COUNT(*) AS catalog_return_cnt,
        SUM(cr_return_quantity) AS catalog_return_qty,
        SUM(cr_return_amount) AS catalog_return_amt,
        SUM(cr_net_loss) AS catalog_net_loss
    FROM catalog_returns
    GROUP BY cr_reason_sk
),
store_agg AS (
    SELECT
        sr_reason_sk,
        COUNT(*) AS store_return_cnt,
        SUM(sr_return_quantity) AS store_return_qty,
        SUM(sr_return_amt) AS store_return_amt,
        SUM(sr_net_loss) AS store_net_loss
    FROM store_returns
    GROUP BY sr_reason_sk
),
joined AS (
    SELECT
        r.r_reason_desc,
        COALESCE(ca.catalog_return_cnt, 0) AS catalog_return_cnt,
        COALESCE(sa.store_return_cnt, 0) AS store_return_cnt,
        COALESCE(ca.catalog_return_qty, 0) AS catalog_return_qty,
        COALESCE(sa.store_return_qty, 0) AS store_return_qty,
        COALESCE(ca.catalog_return_amt, 0) AS catalog_return_amt,
        COALESCE(sa.store_return_amt, 0) AS store_return_amt,
        COALESCE(ca.catalog_net_loss, 0) AS catalog_net_loss,
        COALESCE(sa.store_net_loss, 0) AS store_net_loss,
        COALESCE(ca.catalog_net_loss, 0) + COALESCE(sa.store_net_loss, 0) AS combined_net_loss,
        CASE WHEN COALESCE(sa.store_net_loss, 0) = 0 THEN NULL
             ELSE ROUND(COALESCE(ca.catalog_net_loss, 0) / COALESCE(sa.store_net_loss, 0), 2)
        END AS catalog_to_store_loss_ratio
    FROM reason r
    LEFT JOIN catalog_agg ca ON ca.cr_reason_sk = r.r_reason_sk
    LEFT JOIN store_agg sa ON sa.sr_reason_sk = r.r_reason_sk
)
SELECT
    r_reason_desc,
    catalog_return_cnt,
    store_return_cnt,
    catalog_net_loss,
    store_net_loss,
    combined_net_loss,
    catalog_to_store_loss_ratio,
    ROW_NUMBER() OVER (ORDER BY combined_net_loss DESC) AS net_loss_rank
FROM joined
WHERE COALESCE(catalog_net_loss, 0) + COALESCE(store_net_loss, 0) > 0
ORDER BY net_loss_rank
LIMIT 10
