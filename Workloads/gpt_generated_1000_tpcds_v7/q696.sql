/*
Goal: Combine store return loss data and web sales profit data for the same fiscal year to compare item performance across channels, showing each transaction type and ordering by date and amount.
*/
SELECT
    item_id,
    trans_date,
    amount,
    source
FROM (
    SELECT
        i.i_item_id AS item_id,
        d.d_date   AS trans_date,
        sr.sr_net_loss AS amount,
        'Return'   AS source
    FROM store_returns AS sr
    JOIN item       AS i ON sr.sr_item_sk = i.i_item_sk
    JOIN date_dim   AS d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2002

    UNION ALL

    SELECT
        i.i_item_id AS item_id,
        d.d_date   AS trans_date,
        ws.ws_net_profit AS amount,
        'Sale'     AS source
    FROM web_sales AS ws
    JOIN item     AS i ON ws.ws_item_sk = i.i_item_sk
    JOIN date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
) AS combined
ORDER BY trans_date, amount DESC
