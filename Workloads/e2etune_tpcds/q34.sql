WITH reason_returns AS (
    SELECT
        r.r_reason_desc AS r_reason_desc,
        COUNT(*) AS num_returns,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_net_loss) AS total_net_loss,
        AVG(wr.wr_return_amt) AS avg_return_amt,
        SUM(wr.wr_return_quantity) AS total_quantity
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE wr.wr_returned_date_sk BETWEEN 2450996 AND 2451087
      AND wr.wr_return_amt > 0
    GROUP BY r.r_reason_desc
),
ranked_reasons AS (
    SELECT
        r_reason_desc,
        num_returns,
        total_return_amt,
        total_net_loss,
        avg_return_amt,
        total_quantity,
        RANK() OVER (ORDER BY total_return_amt DESC) AS reason_rank
    FROM reason_returns
)
SELECT
    rr.r_reason_desc,
    rr.num_returns,
    rr.total_return_amt,
    rr.total_net_loss,
    rr.avg_return_amt,
    rr.total_quantity,
    rr.reason_rank,
    (SELECT COUNT(*) FROM catalog_page) AS total_catalog_pages,
    (SELECT COUNT(DISTINCT sm_ship_mode_id) FROM ship_mode) AS distinct_ship_modes
FROM ranked_reasons rr
WHERE rr.reason_rank <= 10
ORDER BY rr.reason_rank
