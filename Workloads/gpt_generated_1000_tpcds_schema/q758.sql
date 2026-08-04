WITH common_items AS (
    SELECT i_item_sk
    FROM (
        SELECT ss.ss_item_sk AS i_item_sk
        FROM store_sales ss
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        WHERE i.i_rec_start_date >= DATE '2000-01-01'
    ) s
    INTERSECT
    SELECT i_item_sk
    FROM (
        SELECT ws.ws_item_sk AS i_item_sk
        FROM web_sales ws
        JOIN item i ON ws.ws_item_sk = i.i_item_sk
        JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
        WHERE i.i_rec_end_date <= DATE '2002-01-01'
    ) w
)
,
store_agg AS (
    SELECT
        ss.ss_item_sk AS i_item_sk,
        ss.ss_customer_sk AS customer_sk,
        SUM(ss.ss_ext_sales_price) AS total_sales
    FROM store_sales ss
    JOIN common_items ci ON ss.ss_item_sk = ci.i_item_sk
    GROUP BY ss.ss_item_sk, ss.ss_customer_sk
)
SELECT
    i.i_item_sk,
    i.i_product_name,
    i.i_current_price,
    c.c_customer_id,
    sa.total_sales,
    (
        SELECT COALESCE(SUM(sr.sr_return_amt), 0)
        FROM store_returns sr
        WHERE sr.sr_item_sk = i.i_item_sk
    ) AS total_store_returns,
    RANK() OVER (PARTITION BY c.c_customer_id ORDER BY sa.total_sales DESC) AS purchase_rank
FROM store_agg sa
JOIN item i ON sa.i_item_sk = i.i_item_sk
JOIN customer c ON sa.customer_sk = c.c_customer_sk
WHERE i.i_current_price = (
    SELECT MIN(i2.i_current_price)
    FROM item i2
)
ORDER BY sa.total_sales DESC
LIMIT 100
