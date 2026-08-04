WITH web_part AS (
    SELECT
        c.c_customer_id,
        i.i_item_id,
        ws.ws_ext_sales_price AS total_amount,
        CASE WHEN ws.ws_ext_discount_amt > 0 THEN 'Discounted' ELSE 'Full Price' END AS price_status,
        'Web' AS sales_channel
    FROM tpcds.web_sales ws
    JOIN tpcds.item i ON ws.ws_item_sk = i.i_item_sk
    JOIN tpcds.customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE EXISTS (
        SELECT 1 FROM tpcds.promotion p
        WHERE p.p_item_sk = i.i_item_sk
    )
      AND i.i_category_id = 5
),
store_part AS (
    SELECT
        c.c_customer_id,
        i.i_item_id,
        sr.sr_return_amt AS total_amount,
        CASE WHEN sr.sr_return_quantity > 1 THEN 'Multiple' ELSE 'Single' END AS price_status,
        'Store' AS sales_channel
    FROM tpcds.store_returns sr
    JOIN tpcds.item i ON sr.sr_item_sk = i.i_item_sk
    JOIN tpcds.customer c ON sr.sr_customer_sk = c.c_customer_sk
    WHERE EXISTS (
        SELECT 1 FROM tpcds.promotion p
        WHERE p.p_item_sk = i.i_item_sk
    )
      AND i.i_category_id = 5
)
SELECT *
FROM web_part
UNION ALL
SELECT *
FROM store_part
ORDER BY total_amount DESC
LIMIT 100
