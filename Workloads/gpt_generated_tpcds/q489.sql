WITH store_sales_monthly AS (
    SELECT
        year(date_dim.d_date) AS sales_year,
        month(date_dim.d_date) AS sales_month,
        item.i_category AS product_category,
        SUM(store_sales.ss_net_profit) AS total_net_profit,
        SUM(store_sales.ss_ext_sales_price) AS total_sales
    FROM store_sales
    JOIN date_dim ON store_sales.ss_sold_date_sk = date_dim.d_date_sk
    JOIN item ON store_sales.ss_item_sk = item.i_item_sk
    WHERE date_dim.d_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'
    GROUP BY year(date_dim.d_date), month(date_dim.d_date), item.i_category
),
web_sales_monthly AS (
    SELECT
        year(date_dim.d_date) AS sales_year,
        month(date_dim.d_date) AS sales_month,
        item.i_category AS product_category,
        SUM(web_sales.ws_net_profit) AS total_net_profit,
        SUM(web_sales.ws_ext_sales_price) AS total_sales
    FROM web_sales
    JOIN date_dim ON web_sales.ws_sold_date_sk = date_dim.d_date_sk
    JOIN item ON web_sales.ws_item_sk = item.i_item_sk
    WHERE date_dim.d_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'
    GROUP BY year(date_dim.d_date), month(date_dim.d_date), item.i_category
),
catalog_sales_monthly AS (
    SELECT
        year(date_dim.d_date) AS sales_year,
        month(date_dim.d_date) AS sales_month,
        item.i_category AS product_category,
        SUM(catalog_sales.cs_net_profit) AS total_net_profit,
        SUM(catalog_sales.cs_ext_sales_price) AS total_sales
    FROM catalog_sales
    JOIN date_dim ON catalog_sales.cs_sold_date_sk = date_dim.d_date_sk
    JOIN item ON catalog_sales.cs_item_sk = item.i_item_sk
    WHERE date_dim.d_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'
    GROUP BY year(date_dim.d_date), month(date_dim.d_date), item.i_category
)
SELECT
    sales_year,
    sales_month,
    product_category,
    'store' AS channel,
    total_net_profit,
    total_sales
FROM store_sales_monthly

UNION ALL

SELECT
    sales_year,
    sales_month,
    product_category,
    'web' AS channel,
    total_net_profit,
    total_sales
FROM web_sales_monthly

UNION ALL

SELECT
    sales_year,
    sales_month,
    product_category,
    'catalog' AS channel,
    total_net_profit,
    total_sales
FROM catalog_sales_monthly
ORDER BY sales_year, sales_month, product_category, channel
