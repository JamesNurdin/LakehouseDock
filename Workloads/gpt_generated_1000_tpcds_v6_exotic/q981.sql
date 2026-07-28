WITH store_ret AS (
    SELECT
        d.d_year,
        d.d_month_seq AS month_seq,
        SUM(sr.sr_return_amt) AS total_return_amt,
        CAST('store' AS varchar) AS channel
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2002-12-31'
    GROUP BY d.d_year, d.d_month_seq
),
web_ret AS (
    SELECT
        d.d_year,
        d.d_month_seq AS month_seq,
        SUM(wr.wr_return_amt) AS total_return_amt,
        CAST('web' AS varchar) AS channel
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2002-12-31'
    GROUP BY d.d_year, d.d_month_seq
),
catalog_ret AS (
    SELECT
        d.d_year,
        d.d_month_seq AS month_seq,
        SUM(cr.cr_return_amount) AS total_return_amt,
        CAST('catalog' AS varchar) AS channel
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2002-12-31'
    GROUP BY d.d_year, d.d_month_seq
)
SELECT
    combined.d_year,
    combined.month_seq,
    combined.total_return_amt,
    combined.channel
FROM (
    SELECT * FROM store_ret
    UNION ALL
    SELECT * FROM web_ret
    UNION ALL
    SELECT * FROM catalog_ret
) AS combined
ORDER BY combined.d_year, combined.month_seq, combined.total_return_amt DESC
LIMIT 100
