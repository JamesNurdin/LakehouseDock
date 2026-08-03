WITH sampled_store_sales AS (
    SELECT *
    FROM store_sales TABLESAMPLE BERNOULLI (10)
    LIMIT 1000
),
store_item_sales AS (
    SELECT
        ss.ss_item_sk AS ss_item_sk,
        i.i_product_name AS product_name,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS sales_rank
    FROM sampled_store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY ss.ss_item_sk, i.i_product_name
),
web_item_sales AS (
    SELECT
        ws.ws_item_sk AS ws_item_sk,
        i.i_product_name AS product_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY ws.ws_item_sk, i.i_product_name
),
intersect_items AS (
    SELECT ss_item_sk AS item_sk FROM store_item_sales
    INTERSECT
    SELECT ws_item_sk FROM web_item_sales
),
store_only_items AS (
    SELECT ss_item_sk AS item_sk FROM store_item_sales
    EXCEPT
    SELECT ws_item_sk FROM web_item_sales
),
full_join_returns_sales AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_item_sk,
        ss.ss_quantity,
        sr.sr_return_quantity,
        sr.sr_return_amt
    FROM store_sales ss
    FULL OUTER JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
        AND ss.ss_item_sk = sr.sr_item_sk
),
final_union AS (
    SELECT item_sk, 'both' AS sales_channel FROM intersect_items
    UNION
    SELECT item_sk, 'store_only' AS sales_channel FROM store_only_items
)
SELECT
    fu.item_sk,
    fu.sales_channel,
    sis.total_sales,
    sis.sales_rank,
    LAG(sis.total_sales) OVER (PARTITION BY fu.sales_channel ORDER BY sis.sales_rank) AS prev_sales
FROM final_union fu
LEFT JOIN store_item_sales sis ON fu.item_sk = sis.ss_item_sk
WHERE fu.sales_channel = 'both'
ORDER BY sis.total_sales DESC
LIMIT 100
