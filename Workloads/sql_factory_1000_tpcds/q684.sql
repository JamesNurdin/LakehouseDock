WITH bucketed AS (
    SELECT
        i.i_manufact,
        d_ret.d_day_name,
        CASE
            WHEN wr.wr_return_amt < 100 THEN '0-99'
            WHEN wr.wr_return_amt < 500 THEN '100-499'
            WHEN wr.wr_return_amt < 1000 THEN '500-999'
            ELSE '1000+'
        END AS amount_bucket,
        wr.wr_return_amt,
        ws.web_state
    FROM web_returns wr
    JOIN date_dim d_ret
        ON wr.wr_returned_date_sk = d_ret.d_date_sk
    JOIN item i
        ON wr.wr_item_sk = i.i_item_sk
    JOIN web_site ws
        ON d_ret.d_date_sk >= ws.web_open_date_sk
       AND (ws.web_close_date_sk IS NULL OR d_ret.d_date_sk <= ws.web_close_date_sk)
    WHERE d_ret.d_year BETWEEN 2002 AND 2004
)
SELECT
    b.i_manufact,
    b.d_day_name,
    b.amount_bucket,
    COUNT(*) AS return_cnt,
    SUM(b.wr_return_amt) AS bucket_return_total,
    b.web_state,
    RANK() OVER (PARTITION BY b.amount_bucket ORDER BY SUM(b.wr_return_amt) DESC) AS bucket_rank
FROM bucketed b
GROUP BY b.i_manufact, b.d_day_name, b.amount_bucket, b.web_state
HAVING SUM(b.wr_return_amt) > 0
ORDER BY b.amount_bucket, bucket_rank
LIMIT 20
