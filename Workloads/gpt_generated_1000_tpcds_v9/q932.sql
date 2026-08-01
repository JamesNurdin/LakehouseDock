WITH filtered AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_net_loss,
        r.r_reason_desc,
        s.s_store_name,
        s.s_store_id
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE regexp_like(r.r_reason_desc, '^Damaged')
      AND s.s_store_name LIKE '%Store%'
),
agg AS (
    SELECT
        f.sr_store_sk,
        SUM(f.sr_net_loss) AS total_net_loss,
        COUNT(*) AS returns_cnt,
        AVG(f.sr_net_loss) AS avg_net_loss
    FROM filtered f
    WHERE NOT EXISTS (
        SELECT 1
        FROM store_returns sr2
        JOIN reason r2 ON sr2.sr_reason_sk = r2.r_reason_sk
        WHERE sr2.sr_store_sk = f.sr_store_sk
          AND regexp_like(r2.r_reason_desc, 'Defective')
    )
    GROUP BY f.sr_store_sk
)
SELECT DISTINCT
    s.s_store_id,
    s.s_store_name,
    pref.store_prefix,
    concat(pref.store_prefix, '-', s.s_store_id) AS store_label,
    a.total_net_loss,
    a.returns_cnt,
    a.avg_net_loss
FROM agg a
JOIN store s ON a.sr_store_sk = s.s_store_sk
CROSS JOIN LATERAL (
    SELECT regexp_extract(s.s_store_name, '^([^ ]+)') AS store_prefix
) AS pref
ORDER BY a.total_net_loss DESC
LIMIT 10
