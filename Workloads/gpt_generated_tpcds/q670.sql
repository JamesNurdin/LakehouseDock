WITH all_returns AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        r.r_reason_desc,
        sr.sr_net_loss AS net_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE d.d_date >= DATE '2000-01-01' AND d.d_date < DATE '2001-01-01'

    UNION ALL

    SELECT
        d.d_year,
        d.d_month_seq,
        r.r_reason_desc,
        cr.cr_net_loss AS net_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE d.d_date >= DATE '2000-01-01' AND d.d_date < DATE '2001-01-01'

    UNION ALL

    SELECT
        d.d_year,
        d.d_month_seq,
        r.r_reason_desc,
        wr.wr_net_loss AS net_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE d.d_date >= DATE '2000-01-01' AND d.d_date < DATE '2001-01-01'
)
SELECT
    d_year,
    d_month_seq,
    r_reason_desc,
    SUM(net_loss) AS total_net_loss
FROM all_returns
GROUP BY
    d_year,
    d_month_seq,
    r_reason_desc
ORDER BY
    total_net_loss DESC
LIMIT 10
