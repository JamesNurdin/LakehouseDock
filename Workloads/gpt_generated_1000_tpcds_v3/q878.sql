WITH agg_returns AS (
    SELECT
        cr_reason_sk,
        COUNT(*) AS return_cnt,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_net_loss) AS total_net_loss,
        AVG(cr_return_amount) AS avg_return_amount
    FROM catalog_returns
    GROUP BY cr_reason_sk
)
SELECT
    r.r_reason_id,
    r.r_reason_desc,
    r.r_reason_sk,
    substring(r.r_reason_desc, 1, 15) AS short_desc,
    regexp_extract(r.r_reason_desc, '^([A-Za-z]+)', 1) AS first_word,
    concat('Reason: ', r.r_reason_desc) AS full_desc,
    agg.return_cnt,
    agg.total_return_amount,
    agg.total_net_loss,
    agg.avg_return_amount,
    (SELECT AVG(cr_net_loss) FROM catalog_returns) AS avg_net_loss_all
FROM reason r
JOIN agg_returns agg
    ON r.r_reason_sk = agg.cr_reason_sk
WHERE
    regexp_like(r.r_reason_desc, '(?i)damaged|price')
    AND r.r_reason_id LIKE 'AAAAAAA%'
    AND agg.total_return_amount > (
        SELECT AVG(cr_return_amount) FROM catalog_returns
    )
ORDER BY agg.total_return_amount DESC, r.r_reason_sk
LIMIT 100
