WITH first AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        SUM(sr.sr_return_amt) AS total_return_amt,
        AVG(sr.sr_return_tax) AS avg_return_tax,
        COUNT(*) AS return_cnt,
        MIN(sr.sr_return_quantity) AS min_qty,
        MAX(sr.sr_return_amt_inc_tax) AS max_amt_inc_tax
    FROM
        store_returns sr TABLESAMPLE BERNOULLI (10)
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE
        d.d_current_month = 'Y'                          -- filter 1
        AND d.d_last_dom = 2415082                        -- filter 2
        AND sr.sr_store_credit > 20                       -- filter 3
    GROUP BY
        d.d_year,
        d.d_month_seq
),
second AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        SUM(sr.sr_return_amt) AS total_return_amt,
        AVG(sr.sr_return_tax) AS avg_return_tax,
        COUNT(*) AS return_cnt,
        MIN(sr.sr_return_quantity) AS min_qty,
        MAX(sr.sr_return_amt_inc_tax) AS max_amt_inc_tax
    FROM
        store_returns sr TABLESAMPLE BERNOULLI (10)
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE
        d.d_current_month = 'N'                          -- filter 4
        AND d.d_same_day_lq = 2414935                     -- filter 5
        AND sr.sr_return_tax > 10                         -- filter 6
    GROUP BY
        d.d_year,
        d.d_month_seq
)
SELECT
    u.year,
    u.month_seq,
    SUM(u.total_return_amt) AS total_return_amt,
    AVG(u.avg_return_tax) AS avg_return_tax,
    SUM(u.return_cnt) AS return_cnt,
    MIN(u.min_qty) AS min_qty,
    MAX(u.max_amt_inc_tax) AS max_amt_inc_tax
FROM (
    SELECT * FROM first
    UNION DISTINCT
    SELECT * FROM second
) u
GROUP BY
    u.year,
    u.month_seq
ORDER BY
    total_return_amt DESC
LIMIT 100
