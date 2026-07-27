WITH sales_monthly AS (
   SELECT
       i.i_item_sk,
       i.i_product_name,
       d.d_year,
       d.d_month_seq,
       SUM(cs.cs_ext_sales_price) AS total_sales,
       SUM(cs.cs_quantity) AS total_quantity
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   WHERE d.d_year = 2001
     AND i.i_category = 'Electronics'
   GROUP BY i.i_item_sk, i.i_product_name, d.d_year, d.d_month_seq
),
returns_monthly AS (
   SELECT
       i.i_item_sk,
       i.i_product_name,
       d.d_year,
       d.d_month_seq,
       SUM(wr.wr_return_amt) AS total_return_amount,
       SUM(wr.wr_return_quantity) AS total_return_qty
   FROM web_returns wr
   JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
   JOIN item i ON wr.wr_item_sk = i.i_item_sk
   WHERE d.d_year = 2001
     AND i.i_category = 'Electronics'
   GROUP BY i.i_item_sk, i.i_product_name, d.d_year, d.d_month_seq
)
SELECT
    item_sk,
    product_name,
    year,
    month_seq,
    total_amount,
    total_units,
    source_type
FROM (
    SELECT
        i_item_sk AS item_sk,
        i_product_name AS product_name,
        d_year AS year,
        d_month_seq AS month_seq,
        total_sales AS total_amount,
        total_quantity AS total_units,
        CAST('sale' AS varchar) AS source_type
    FROM sales_monthly
    UNION ALL
    SELECT
        i_item_sk AS item_sk,
        i_product_name AS product_name,
        d_year AS year,
        d_month_seq AS month_seq,
        total_return_amount AS total_amount,
        total_return_qty AS total_units,
        CAST('return' AS varchar) AS source_type
    FROM returns_monthly
) AS combined
ORDER BY year, month_seq, total_amount DESC
LIMIT 100
