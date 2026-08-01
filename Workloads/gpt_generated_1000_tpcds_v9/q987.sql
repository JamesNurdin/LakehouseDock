WITH purchase_items AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        array_agg(DISTINCT i.i_item_id) AS purchased_items,
        sum(ws.ws_ext_sales_price) AS total_spent,
        max(d.d_date) AS last_purchase_date
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY c.c_customer_sk, c.c_customer_id
)
SELECT
    source,
    c_customer_id,
    c_customer_sk,
    item_id,
    transaction_date,
    amount,
    rn
FROM (
    SELECT
        'purchase' AS source,
        pi.c_customer_id AS c_customer_id,
        pi.c_customer_sk AS c_customer_sk,
        itm.item_id AS item_id,
        pi.last_purchase_date AS transaction_date,
        pi.total_spent AS amount,
        ROW_NUMBER() OVER (PARTITION BY pi.c_customer_id ORDER BY pi.last_purchase_date DESC) AS rn
    FROM purchase_items pi
    CROSS JOIN UNNEST(pi.purchased_items) AS itm(item_id)
    UNION ALL
    SELECT
        'return' AS source,
        c.c_customer_id AS c_customer_id,
        c.c_customer_sk AS c_customer_sk,
        i.i_item_id AS item_id,
        d.d_date AS transaction_date,
        -wr.wr_return_amt AS amount,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY d.d_date DESC) AS rn
    FROM web_returns wr
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
) AS combined
ORDER BY source, c_customer_id, rn
