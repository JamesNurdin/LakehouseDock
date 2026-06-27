WITH store_return_summary AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        dr.d_year,
        dr.d_quarter_name,
        COUNT(*) AS return_cnt,
        SUM(sr.sr_return_quantity) AS total_qty,
        SUM(sr.sr_net_loss) AS total_net_loss,
        AVG(sr.sr_net_loss) AS avg_net_loss
    FROM store_returns sr
    JOIN date_dim dr
        ON sr.sr_returned_date_sk = dr.d_date_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN date_dim dclosed
        ON s.s_closed_date_sk = dclosed.d_date_sk
    WHERE dr.d_year = 2001
      AND (s.s_closed_date_sk IS NULL OR dclosed.d_date > DATE '2001-12-31')
    GROUP BY s.s_store_sk, s.s_store_name, dr.d_year, dr.d_quarter_name
)
SELECT
    srs.s_store_name,
    srs.d_year,
    srs.d_quarter_name,
    srs.return_cnt,
    srs.total_qty,
    srs.total_net_loss,
    srs.avg_net_loss,
    RANK() OVER (ORDER BY srs.total_net_loss DESC) AS net_loss_rank
FROM store_return_summary srs
ORDER BY srs.total_net_loss DESC
LIMIT 10
