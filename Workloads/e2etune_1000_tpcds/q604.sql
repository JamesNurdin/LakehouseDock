WITH reason_returns AS (
    SELECT
        r.r_reason_desc,
        r.r_reason_id,
        COUNT(*) AS num_returns,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_return_tax) AS total_tax,
        AVG(wr.wr_return_amt) AS avg_return_amt,
        SUM(wr.wr_return_quantity) AS total_quantity,
        SUM(wr.wr_net_loss) AS total_net_loss
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE wr.wr_return_amt > 100
      AND r.r_reason_desc IN ('Package was damaged', 'Stopped working')
      AND wr.wr_web_page_sk IN (2221, 14, 1132)
    GROUP BY r.r_reason_desc, r.r_reason_id
)
SELECT
    rr.r_reason_desc,
    rr.r_reason_id,
    rr.num_returns,
    rr.total_return_amt,
    rr.total_tax,
    rr.avg_return_amt,
    rr.total_quantity,
    rr.total_net_loss,
    rr.total_return_amt / NULLIF(rr.total_tax, 0) AS return_to_tax_ratio,
    RANK() OVER (ORDER BY rr.total_return_amt DESC) AS return_amount_rank
FROM reason_returns rr
ORDER BY rr.total_return_amt DESC
LIMIT 10
