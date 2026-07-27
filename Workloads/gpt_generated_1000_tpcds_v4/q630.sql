SELECT
    i.i_item_id,
    d.d_date AS return_date,
    sr.sr_return_amt AS return_amount,
    CAST('store' AS varchar) AS channel,
    (
        SELECT avg(sr2.sr_return_amt)
        FROM store_returns sr2
        WHERE sr2.sr_item_sk = sr.sr_item_sk
    ) AS avg_return_amount_per_item
FROM store_returns sr
JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
JOIN item i ON sr.sr_item_sk = i.i_item_sk
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
WHERE d.d_year = 2001
  AND EXISTS (
        SELECT 1
        FROM web_returns wr
        WHERE wr.wr_item_sk = sr.sr_item_sk
          AND wr.wr_returned_date_sk = sr.sr_returned_date_sk
    )
UNION ALL
SELECT
    i.i_item_id,
    d.d_date AS return_date,
    wr.wr_return_amt AS return_amount,
    CAST('web' AS varchar) AS channel,
    (
        SELECT avg(wr2.wr_return_amt)
        FROM web_returns wr2
        WHERE wr2.wr_item_sk = wr.wr_item_sk
    ) AS avg_return_amount_per_item
FROM web_returns wr
JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
JOIN item i ON wr.wr_item_sk = i.i_item_sk
JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
WHERE d.d_year = 2001
  AND EXISTS (
        SELECT 1
        FROM store_returns sr
        WHERE sr.sr_item_sk = wr.wr_item_sk
          AND sr.sr_returned_date_sk = wr.wr_returned_date_sk
    )
ORDER BY return_date, i_item_id, channel
