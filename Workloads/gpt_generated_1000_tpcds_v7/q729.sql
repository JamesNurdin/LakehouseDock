WITH agg AS (
    SELECT
        d.d_year,
        cc.cc_name,
        SUM(sr.sr_net_loss) AS total_net_loss
    FROM
        tpcds.store_returns sr
        JOIN tpcds.date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        JOIN tpcds.call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
    WHERE
        sr.sr_return_amt > 150
        AND sr.sr_return_tax < 20
        AND sr.sr_refunded_cash BETWEEN 0 AND 300
        AND cc.cc_zip LIKE '3%'
        AND cc.cc_mkt_class LIKE '%workers%'
        AND d.d_current_year = 'Y'
    GROUP BY
        d.d_year,
        cc.cc_name
)
SELECT
    d_year,
    cc_name,
    total_net_loss,
    RANK() OVER (PARTITION BY d_year ORDER BY total_net_loss DESC) AS loss_rank
FROM agg
ORDER BY d_year, loss_rank
