WITH combined_returns AS (
    SELECT
        c.c_customer_id AS customer_id,
        'store' AS channel,
        sr.sr_return_amt AS return_amount,
        sr.sr_return_quantity AS return_quantity,
        r.r_reason_desc AS reason,
        sr.sr_returned_date_sk AS return_date_sk,
        CASE WHEN sr.sr_return_amt > 100 THEN 'High' ELSE 'Low' END AS amount_category
    FROM store_returns sr
    JOIN store_sales ss
        ON sr.sr_ticket_number = ss.ss_ticket_number
       AND sr.sr_item_sk = ss.ss_item_sk
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    WHERE sr.sr_return_amt IS NOT NULL

    UNION ALL

    SELECT
        c.c_customer_id AS customer_id,
        'web' AS channel,
        wr.wr_return_amt AS return_amount,
        wr.wr_return_quantity AS return_quantity,
        r.r_reason_desc AS reason,
        wr.wr_returned_date_sk AS return_date_sk,
        CASE WHEN wr.wr_return_amt > 100 THEN 'High' ELSE 'Low' END AS amount_category
    FROM web_returns wr
    JOIN web_sales ws
        ON wr.wr_order_number = ws.ws_order_number
       AND wr.wr_item_sk = ws.ws_item_sk
    JOIN customer c
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    WHERE wr.wr_return_amt IS NOT NULL
)
SELECT
    customer_id,
    channel,
    return_amount,
    return_quantity,
    reason,
    return_date_sk,
    amount_category,
    SUM(return_amount) OVER (PARTITION BY customer_id) AS total_return_amount,
    ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY return_amount DESC) AS rn
FROM combined_returns
ORDER BY total_return_amount DESC, rn
LIMIT 100
