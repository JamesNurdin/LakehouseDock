WITH store_ret AS (
    SELECT
        i.i_item_id AS item_id,
        i.i_item_desc AS item_desc,
        sr.sr_return_amt AS return_amount,
        td.t_hour AS return_hour,
        r.r_reason_desc AS reason_desc
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE sr.sr_store_sk IN (
            SELECT s.s_store_sk
            FROM store s
            WHERE s.s_state = 'CA'
        )
      AND i.i_current_price > 100
      AND sr.sr_return_amt > 0
),
web_ret AS (
    SELECT
        i.i_item_id AS item_id,
        i.i_item_desc AS item_desc,
        wr.wr_return_amt AS return_amount,
        td.t_hour AS return_hour,
        r.r_reason_desc AS reason_desc
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE wr.wr_returned_date_sk IN (
            SELECT ws.ws_sold_date_sk
            FROM web_sales ws
            WHERE ws.ws_quantity > 5
        )
      AND i.i_current_price > 100
      AND wr.wr_return_amt > 0
)
SELECT
    item_id,
    item_desc,
    return_amount,
    return_hour,
    reason_desc
FROM store_ret
UNION
SELECT
    item_id,
    item_desc,
    return_amount,
    return_hour,
    reason_desc
FROM web_ret
ORDER BY return_amount DESC, return_hour ASC
LIMIT 100
