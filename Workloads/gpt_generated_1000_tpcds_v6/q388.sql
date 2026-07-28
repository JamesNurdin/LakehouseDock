WITH filtered_dates AS (
    SELECT d_date_sk
    FROM date_dim
    WHERE d_year = 2001
      AND d_month_seq BETWEEN 1 AND 12
)
SELECT
    item_id,
    product_name,
    SUM(sales_amount) AS total_sales
FROM (
    SELECT
        i.i_item_id   AS item_id,
        i.i_product_name AS product_name,
        ss.ss_ext_sales_price AS sales_amount
    FROM store_sales ss
    JOIN filtered_dates fd ON ss.ss_sold_date_sk = fd.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE ss.ss_quantity > 0

    UNION ALL

    SELECT
        i.i_item_id   AS item_id,
        i.i_product_name AS product_name,
        ws.ws_ext_sales_price AS sales_amount
    FROM web_sales ws
    JOIN filtered_dates fd ON ws.ws_sold_date_sk = fd.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE ws.ws_quantity > 0
) AS combined
GROUP BY item_id, product_name
ORDER BY total_sales DESC
LIMIT 100
