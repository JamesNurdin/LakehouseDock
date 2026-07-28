WITH agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        AVG(cr.cr_fee) AS avg_fee,
        COUNT(*) AS return_cnt,
        (SELECT AVG(cr2.cr_return_amt_inc_tax) FROM catalog_returns cr2) AS overall_avg_return_amt_inc_tax
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE cr.cr_fee > 50.00
        AND cr.cr_return_amt_inc_tax BETWEEN 1000 AND 5000
        AND d.d_current_month = 'Y'
    GROUP BY d.d_year, d.d_month_seq
)
SELECT
    a.d_year,
    a.d_month_seq,
    a.total_return_amount,
    a.total_net_loss,
    a.avg_fee,
    a.return_cnt,
    a.overall_avg_return_amt_inc_tax,
    RANK() OVER (PARTITION BY a.d_year ORDER BY a.total_net_loss DESC) AS net_loss_rank,
    SUM(a.total_return_amount) OVER (PARTITION BY a.d_year) AS year_total_return_amount
FROM agg a
ORDER BY a.d_year DESC, a.total_net_loss DESC
LIMIT 100
