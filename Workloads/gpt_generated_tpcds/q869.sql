WITH catalog_sales_agg AS (
    SELECT
        date_dim.d_date AS sale_date,
        item.i_category AS category,
        SUM(catalog_sales.cs_ext_sales_price) AS sales_amount,
        SUM(catalog_sales.cs_net_profit) AS net_profit
    FROM catalog_sales
    JOIN date_dim ON catalog_sales.cs_sold_date_sk = date_dim.d_date_sk
    JOIN item ON catalog_sales.cs_item_sk = item.i_item_sk
    WHERE date_dim.d_date >= DATE '2001-01-01' AND date_dim.d_date < DATE '2002-01-01'
    GROUP BY date_dim.d_date, item.i_category
),
store_sales_agg AS (
    SELECT
        date_dim.d_date AS sale_date,
        item.i_category AS category,
        SUM(store_sales.ss_ext_sales_price) AS sales_amount,
        SUM(store_sales.ss_net_profit) AS net_profit
    FROM store_sales
    JOIN date_dim ON store_sales.ss_sold_date_sk = date_dim.d_date_sk
    JOIN item ON store_sales.ss_item_sk = item.i_item_sk
    WHERE date_dim.d_date >= DATE '2001-01-01' AND date_dim.d_date < DATE '2002-01-01'
    GROUP BY date_dim.d_date, item.i_category
),
web_sales_agg AS (
    SELECT
        date_dim.d_date AS sale_date,
        item.i_category AS category,
        SUM(web_sales.ws_ext_sales_price) AS sales_amount,
        SUM(web_sales.ws_net_profit) AS net_profit
    FROM web_sales
    JOIN date_dim ON web_sales.ws_sold_date_sk = date_dim.d_date_sk
    JOIN item ON web_sales.ws_item_sk = item.i_item_sk
    WHERE date_dim.d_date >= DATE '2001-01-01' AND date_dim.d_date < DATE '2002-01-01'
    GROUP BY date_dim.d_date, item.i_category
)
SELECT
    sale_date,
    category,
    SUM(sales_amount) AS total_sales,
    SUM(net_profit) AS total_profit
FROM (
    SELECT sale_date, category, sales_amount, net_profit FROM catalog_sales_agg
    UNION ALL
    SELECT sale_date, category, sales_amount, net_profit FROM store_sales_agg
    UNION ALL
    SELECT sale_date, category, sales_amount, net_profit FROM web_sales_agg
) AS combined
GROUP BY sale_date, category
ORDER BY sale_date, category
