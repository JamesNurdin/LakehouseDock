WITH catalog_ret AS (
    SELECT
        c.c_customer_sk   AS customer_sk,
        c.c_customer_id   AS customer_id,
        i.i_item_id       AS item_id,
        cr.cr_return_amount AS return_amount,
        cr.cr_returned_date_sk AS return_date_key,
        'catalog'         AS channel
    FROM catalog_returns cr
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN item i     ON cr.cr_item_sk = i.i_item_sk
    WHERE cr.cr_net_loss > 500
      AND NOT EXISTS (
            SELECT 1
            FROM web_returns wr
            WHERE wr.wr_order_number = cr.cr_order_number
        )
),
web_ret AS (
    SELECT
        c.c_customer_sk   AS customer_sk,
        c.c_customer_id   AS customer_id,
        i.i_item_id       AS item_id,
        wr.wr_return_amt  AS return_amount,
        wr.wr_returned_date_sk AS return_date_key,
        'web'             AS channel
    FROM web_returns wr
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN item i     ON wr.wr_item_sk = i.i_item_sk
    WHERE wr.wr_return_amt > 500
      AND NOT EXISTS (
            SELECT 1
            FROM catalog_returns cr
            WHERE cr.cr_order_number = wr.wr_order_number
        )
),
combined_returns AS (
    SELECT * FROM catalog_ret
    UNION ALL
    SELECT * FROM web_ret
)
SELECT
    cr.customer_id,
    COUNT(DISTINCT cr.item_id)            AS distinct_items_returned,
    SUM(cr.return_amount)                 AS total_return_amount,
    MIN(cr.return_date_key)               AS earliest_return_key,
    MAX(cr.return_date_key)               AS latest_return_key
FROM combined_returns cr
WHERE NOT EXISTS (
    SELECT 1
    FROM store_sales ss
    WHERE ss.ss_customer_sk = cr.customer_sk
)
GROUP BY cr.customer_id
ORDER BY total_return_amount DESC
LIMIT 100
