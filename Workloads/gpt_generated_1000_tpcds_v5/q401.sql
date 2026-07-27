WITH store_ret AS (
    SELECT
        i.i_item_id AS item_id,
        i.i_item_desc AS item_desc,
        'store' AS return_channel,
        sr.sr_return_amt AS return_amt,
        sr.sr_return_quantity AS return_qty
    FROM store_returns sr
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    WHERE i.i_brand_id = 3003001
      AND sr.sr_return_amt > 100
),
web_ret AS (
    SELECT
        i.i_item_id AS item_id,
        i.i_item_desc AS item_desc,
        'web' AS return_channel,
        wr.wr_return_amt AS return_amt,
        wr.wr_return_quantity AS return_qty
    FROM web_returns wr
    JOIN item i
        ON wr.wr_item_sk = i.i_item_sk
    WHERE i.i_brand_id = 3003001
      AND wr.wr_return_amt > 100
)
SELECT *
FROM (
    SELECT * FROM store_ret
    UNION ALL
    SELECT * FROM web_ret
) combined
ORDER BY return_amt DESC
LIMIT 100
