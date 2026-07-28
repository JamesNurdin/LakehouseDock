WITH weekend_returns AS (
    SELECT
        agg.d_quarter_seq,
        agg.total_return_amt,
        agg.total_fee,
        ROW_NUMBER() OVER (PARTITION BY agg.d_quarter_seq ORDER BY agg.total_return_amt DESC) AS quarter_rank
    FROM (
        SELECT
            d.d_quarter_seq,
            SUM(sr.sr_return_amt) AS total_return_amt,
            SUM(sr.sr_fee) AS total_fee
        FROM store_returns AS sr
        JOIN date_dim AS d
            ON sr.sr_returned_date_sk = d.d_date_sk
        WHERE d.d_weekend = 'Y'
          AND sr.sr_fee > 20
        GROUP BY d.d_quarter_seq
    ) AS agg
),
weekday_returns AS (
    SELECT
        agg.d_quarter_seq,
        agg.total_return_amt,
        agg.total_fee,
        ROW_NUMBER() OVER (PARTITION BY agg.d_quarter_seq ORDER BY agg.total_return_amt DESC) AS quarter_rank
    FROM (
        SELECT
            d.d_quarter_seq,
            SUM(sr.sr_return_amt) AS total_return_amt,
            SUM(sr.sr_fee) AS total_fee
        FROM store_returns AS sr
        JOIN date_dim AS d
            ON sr.sr_returned_date_sk = d.d_date_sk
        WHERE d.d_weekend = 'N'
          AND sr.sr_store_credit > 10
        GROUP BY d.d_quarter_seq
    ) AS agg
)
SELECT
    d_quarter_seq,
    total_return_amt,
    total_fee,
    quarter_rank
FROM weekend_returns
UNION ALL
SELECT
    d_quarter_seq,
    total_return_amt,
    total_fee,
    quarter_rank
FROM weekday_returns
ORDER BY d_quarter_seq, quarter_rank
