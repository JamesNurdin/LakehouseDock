WITH
    catalog_agg AS (
        SELECT
            d.d_date AS sale_date,
            i.i_item_id AS item_id,
            i.i_product_name AS product_name,
            SUM(cs.cs_ext_sales_price) AS total_sales
        FROM catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        WHERE d.d_year = 2001
          AND d.d_holiday = 'N'
        GROUP BY d.d_date, i.i_item_id, i.i_product_name
    ),
    store_agg AS (
        SELECT
            d.d_date AS sale_date,
            i.i_item_id AS item_id,
            i.i_product_name AS product_name,
            SUM(ss.ss_ext_sales_price) AS total_sales
        FROM store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        WHERE d.d_year = 2001
          AND d.d_holiday = 'N'
        GROUP BY d.d_date, i.i_item_id, i.i_product_name
    )
SELECT
    sale_date,
    item_id,
    product_name,
    total_sales
FROM (
    SELECT sale_date, item_id, product_name, total_sales FROM catalog_agg
    UNION ALL
    SELECT sale_date, item_id, product_name, total_sales FROM store_agg
) AS combined
ORDER BY total_sales DESC
LIMIT 100
