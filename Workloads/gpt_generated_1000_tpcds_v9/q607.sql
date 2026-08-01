WITH
    store_ret AS (
        SELECT
            date_format(d.d_date, '%Y-%m') AS return_month,
            i.i_category AS category,
            sum(sr.sr_return_amt) AS total_return_amount,
            count(*) AS total_returns,
            'store' AS source
        FROM store_returns sr
        INNER JOIN date_dim d
            ON sr.sr_returned_date_sk = d.d_date_sk
        INNER JOIN item i
            ON sr.sr_item_sk = i.i_item_sk
        LEFT JOIN promotion p
            ON p.p_item_sk = i.i_item_sk
            AND p.p_discount_active = 'Y'
        WHERE d.d_year = 2001
          AND sr.sr_return_amt > (SELECT avg(sr2.sr_return_amt) FROM store_returns sr2)
        GROUP BY date_format(d.d_date, '%Y-%m'), i.i_category
    ),
    web_ret AS (
        SELECT
            date_format(d2.d_date, '%Y-%m') AS return_month,
            i2.i_category AS category,
            sum(wr.wr_return_amt) AS total_return_amount,
            count(*) AS total_returns,
            'web' AS source
        FROM web_returns wr
        INNER JOIN date_dim d2
            ON wr.wr_returned_date_sk = d2.d_date_sk
        INNER JOIN item i2
            ON wr.wr_item_sk = i2.i_item_sk
        WHERE d2.d_year = 2001
          AND wr.wr_return_amt > (SELECT avg(wr2.wr_return_amt) FROM web_returns wr2)
        GROUP BY date_format(d2.d_date, '%Y-%m'), i2.i_category
    )
SELECT
    combined.return_month,
    combined.category,
    combined.total_return_amount,
    combined.total_returns,
    combined.source
FROM (
    SELECT * FROM store_ret
    UNION ALL
    SELECT * FROM web_ret
) AS combined
ORDER BY combined.return_month,
         combined.total_return_amount DESC
LIMIT 100
