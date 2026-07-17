WITH catalog_agg AS (
    SELECT
        r.r_reason_id,
        r.r_reason_desc,
        SUM(cr.cr_net_loss) AS net_loss,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
    WHERE d_cr.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
    GROUP BY r.r_reason_id, r.r_reason_desc
),
web_agg AS (
    SELECT
        r.r_reason_id,
        r.r_reason_desc,
        SUM(wr.wr_net_loss) AS net_loss,
        COUNT(*) AS return_cnt
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
    WHERE d_wr.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
    GROUP BY r.r_reason_id, r.r_reason_desc
),
combined AS (
    SELECT r_reason_id, r_reason_desc, net_loss, return_cnt FROM catalog_agg
    UNION ALL
    SELECT r_reason_id, r_reason_desc, net_loss, return_cnt FROM web_agg
),
per_reason_total AS (
    SELECT
        r_reason_id,
        r_reason_desc,
        SUM(net_loss) AS total_net_loss,
        SUM(return_cnt) AS total_return_cnt
    FROM combined
    GROUP BY r_reason_id, r_reason_desc
),
overall AS (
    SELECT AVG(total_net_loss) AS avg_net_loss FROM per_reason_total
)
SELECT
    pr.r_reason_id,
    pr.r_reason_desc,
    pr.total_net_loss,
    pr.total_return_cnt
FROM per_reason_total pr
CROSS JOIN overall o
WHERE pr.total_net_loss > o.avg_net_loss
ORDER BY pr.total_net_loss DESC
LIMIT 10
