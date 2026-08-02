WITH sales AS (
    SELECT
        cs.cs_item_sk AS item_sk,
        i.i_product_name AS product_name,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        COUNT(*) AS sales_cnt,
        MIN(cs.cs_sales_price) AS min_sales_price,
        MAX(cs.cs_sales_price) AS max_sales_price
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE regexp_like(i.i_product_name, '^.*[0-9]{2,}.*$')
      AND cp.cp_description LIKE '%Holiday%'
    GROUP BY cs.cs_item_sk, i.i_product_name
),
returns AS (
    SELECT
        wr.wr_item_sk AS item_sk,
        i2.i_product_name AS product_name,
        SUM(wr.wr_return_amt) AS total_return_amount,
        COUNT(*) AS return_cnt,
        AVG(wr.wr_return_quantity) AS avg_return_qty
    FROM web_returns wr
    JOIN item i2 ON wr.wr_item_sk = i2.i_item_sk
    WHERE regexp_like(i2.i_product_name, '.*(Pro|Premium).*')
      AND i2.i_color LIKE 'Red%'
    GROUP BY wr.wr_item_sk, i2.i_product_name
)
SELECT
    COALESCE(sales.item_sk, returns.item_sk) AS item_sk,
    COALESCE(sales.product_name, returns.product_name) AS product_name,
    sales.total_sales,
    sales.sales_cnt,
    returns.total_return_amount,
    returns.return_cnt,
    (sales.total_sales - COALESCE(returns.total_return_amount, 0)) AS net_sales_minus_returns,
    CONCAT('SKU-', CAST(COALESCE(sales.item_sk, returns.item_sk) AS VARCHAR)) AS sku_code
FROM sales
FULL OUTER JOIN returns
    ON sales.item_sk = returns.item_sk
ORDER BY net_sales_minus_returns DESC
LIMIT 100
