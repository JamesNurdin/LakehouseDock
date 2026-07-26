WITH store_loss AS (
    SELECT sr.sr_reason_sk, SUM(sr.sr_net_loss) AS total_store_net_loss
    FROM store_returns sr
    GROUP BY sr.sr_reason_sk
),
web_loss AS (
    SELECT wr.wr_reason_sk, SUM(wr.wr_net_loss) AS total_web_net_loss
    FROM web_returns wr
    GROUP BY wr.wr_reason_sk
)
SELECT
    r.r_reason_desc,
    COALESCE(s.total_store_net_loss, 0) AS store_net_loss,
    COALESCE(w.total_web_net_loss, 0) AS web_net_loss,
    CASE 
        WHEN COALESCE(w.total_web_net_loss, 0) = 0 THEN NULL
        ELSE COALESCE(s.total_store_net_loss, 0) / COALESCE(w.total_web_net_loss, 0)
    END AS store_to_web_loss_ratio,
    CASE
        WHEN COALESCE(s.total_store_net_loss, 0) > COALESCE(w.total_web_net_loss, 0) * 2 THEN 'High Store Loss'
        WHEN COALESCE(w.total_web_net_loss, 0) > COALESCE(s.total_store_net_loss, 0) * 2 THEN 'High Web Loss'
        ELSE 'Balanced'
    END AS loss_balance_category,
    ROW_NUMBER() OVER (ORDER BY CASE 
                                WHEN COALESCE(w.total_web_net_loss, 0) = 0 THEN 0
                                ELSE COALESCE(s.total_store_net_loss, 0) / COALESCE(w.total_web_net_loss, 0)
                            END DESC) AS loss_ratio_rank
FROM reason r
LEFT JOIN store_loss s ON r.r_reason_sk = s.sr_reason_sk
LEFT JOIN web_loss w ON r.r_reason_sk = w.wr_reason_sk
WHERE COALESCE(s.total_store_net_loss, 0) + COALESCE(w.total_web_net_loss, 0) > 0
ORDER BY loss_ratio_rank
LIMIT 10
