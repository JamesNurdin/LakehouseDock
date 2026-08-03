WITH returns_combined AS (
    SELECT
        d.d_year,
        d.d_month_seq AS month,
        SUM(sr.sr_net_loss) AS total_net_loss,
        SUM(sr.sr_return_amt) AS total_return_amt,
        'store' AS return_source
    FROM store_returns AS sr
    JOIN date_dim AS d
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN reason AS r
        ON sr.sr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
      AND r.r_reason_desc LIKE '%warranty%'
    GROUP BY d.d_year, d.d_month_seq
    UNION ALL
    SELECT
        d.d_year,
        d.d_month_seq AS month,
        SUM(wr.wr_net_loss) AS total_net_loss,
        SUM(wr.wr_return_amt) AS total_return_amt,
        'web' AS return_source
    FROM web_returns AS wr
    JOIN date_dim AS d
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN reason AS r
        ON wr.wr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
      AND r.r_reason_desc LIKE '%product%'
    GROUP BY d.d_year, d.d_month_seq
)
SELECT
    r.d_year,
    r.month,
    r.return_source,
    r.total_net_loss,
    r.total_return_amt
FROM returns_combined AS r
ORDER BY r.d_year, r.month, r.return_source
LIMIT 100
