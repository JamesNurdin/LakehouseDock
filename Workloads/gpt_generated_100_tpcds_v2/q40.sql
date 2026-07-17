WITH catalog_agg AS (
    SELECT
        cr.cr_reason_sk,
        w.w_gmt_offset,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss
    FROM catalog_returns cr
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    GROUP BY cr.cr_reason_sk, w.w_gmt_offset
), reason_agg AS (
    SELECT
        r.r_reason_id,
        r.r_reason_desc,
        AVG(ca.total_return_amount) AS avg_return_amount_per_offset,
        AVG(ca.total_net_loss) AS avg_net_loss_per_offset
    FROM catalog_agg ca
    JOIN reason r
        ON ca.cr_reason_sk = r.r_reason_sk
    GROUP BY r.r_reason_id, r.r_reason_desc
)
SELECT
    r_reason_id,
    r_reason_desc,
    avg_return_amount_per_offset,
    avg_net_loss_per_offset
FROM reason_agg
WHERE avg_return_amount_per_offset > 500
ORDER BY avg_return_amount_per_offset DESC
