WITH returns_agg AS (
    SELECT
        wr_web_page_sk,
        wr_reason_sk,
        SUM(wr_return_quantity) AS total_return_qty,
        SUM(wr_return_amt) AS total_return_amt,
        SUM(wr_net_loss) AS total_net_loss,
        COUNT(*) AS return_count
    FROM web_returns
    GROUP BY wr_web_page_sk, wr_reason_sk
),
joined AS (
    SELECT
        r.r_reason_desc,
        wp.wp_type,
        ra.total_return_qty,
        ra.total_return_amt,
        ra.total_net_loss,
        ra.return_count
    FROM returns_agg ra
    JOIN reason r
        ON ra.wr_reason_sk = r.r_reason_sk
    JOIN web_page wp
        ON ra.wr_web_page_sk = wp.wp_web_page_sk
)
SELECT
    r_reason_desc,
    wp_type,
    return_count,
    total_return_qty,
    total_return_amt,
    total_net_loss,
    (total_return_amt / NULLIF(total_return_qty, 0)) AS avg_return_amt_per_qty,
    (total_net_loss / SUM(total_net_loss) OVER (PARTITION BY r_reason_desc)) * 100 AS pct_of_reason_loss,
    RANK() OVER (PARTITION BY r_reason_desc ORDER BY total_net_loss DESC) AS page_rank
FROM joined
ORDER BY total_net_loss DESC
LIMIT 200
