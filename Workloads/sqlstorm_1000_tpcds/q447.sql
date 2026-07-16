WITH all_sales AS (
    SELECT
        i.i_item_sk,
        DATE_TRUNC('month', d.d_date) AS month,
        'store' AS channel,
        ss.ss_ext_sales_price AS sales,
        ss.ss_net_profit AS profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    UNION ALL
    SELECT
        i.i_item_sk,
        DATE_TRUNC('month', d.d_date) AS month,
        'catalog' AS channel,
        cs.cs_ext_sales_price AS sales,
        cs.cs_net_profit AS profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    UNION ALL
    SELECT
        i.i_item_sk,
        DATE_TRUNC('month', d.d_date) AS month,
        'web' AS channel,
        ws.ws_ext_sales_price AS sales,
        ws.ws_net_profit AS profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
),
sales_pivot AS (
    SELECT
        i_item_sk,
        month,
        SUM(CASE WHEN channel = 'store' THEN sales ELSE 0 END) AS store_sales,
        SUM(CASE WHEN channel = 'catalog' THEN sales ELSE 0 END) AS catalog_sales,
        SUM(CASE WHEN channel = 'web' THEN sales ELSE 0 END) AS web_sales,
        SUM(CASE WHEN channel = 'store' THEN profit ELSE 0 END) AS store_profit,
        SUM(CASE WHEN channel = 'catalog' THEN profit ELSE 0 END) AS catalog_profit,
        SUM(CASE WHEN channel = 'web' THEN profit ELSE 0 END) AS web_profit,
        SUM(sales) AS total_sales,
        SUM(profit) AS total_profit
    FROM all_sales
    GROUP BY i_item_sk, month
),
item_details AS (
    SELECT
        i_item_sk,
        i_product_name,
        i_brand,
        i_category,
        i_class
    FROM item
),
ranked AS (
    SELECT
        sp.month,
        id.i_category,
        id.i_class,
        id.i_brand,
        id.i_product_name,
        sp.store_sales,
        sp.catalog_sales,
        sp.web_sales,
        sp.total_sales,
        sp.total_profit,
        ROW_NUMBER() OVER (PARTITION BY sp.month ORDER BY sp.total_sales DESC) AS sales_rank,
        SUM(sp.total_sales) OVER (PARTITION BY sp.month) AS month_total_sales,
        AVG(sp.total_sales) OVER (PARTITION BY sp.i_item_sk ORDER BY sp.month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg_3m_sales
    FROM sales_pivot sp
    JOIN item_details id ON sp.i_item_sk = id.i_item_sk
    WHERE sp.total_sales > 10000
)
SELECT
    month,
    i_category,
    i_class,
    i_brand,
    i_product_name,
    total_sales,
    total_profit,
    store_sales,
    catalog_sales,
    web_sales,
    moving_avg_3m_sales,
    sales_rank,
    ROUND(total_sales / month_total_sales * 100, 2) AS pct_of_month_sales
FROM ranked
WHERE sales_rank <= 10
ORDER BY month, sales_rank
