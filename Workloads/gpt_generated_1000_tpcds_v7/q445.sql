WITH sales AS (
    SELECT dd.d_date AS transaction_date,
           i.i_item_id,
           i.i_product_name,
           ss.ss_ext_sales_price AS amount,
           'sale' AS transaction_type
    FROM store_sales ss
    JOIN date_dim dd ON ss.ss_sold_date_sk = dd.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE dd.d_year = 2001
      AND i.i_current_price > 50
),
returns AS (
    SELECT dd.d_date AS transaction_date,
           i.i_item_id,
           i.i_product_name,
           -wr.wr_return_amt AS amount,
           'return' AS transaction_type
    FROM web_returns wr
    JOIN date_dim dd ON wr.wr_returned_date_sk = dd.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE dd.d_year = 2001
      AND i.i_current_price > 50
)
SELECT transaction_date,
       i_item_id,
       i_product_name,
       amount,
       transaction_type
FROM sales
UNION ALL
SELECT transaction_date,
       i_item_id,
       i_product_name,
       amount,
       transaction_type
FROM returns
ORDER BY transaction_date DESC
LIMIT 100
