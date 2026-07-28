-- Goal: Compare daily revenue by product category between the store and web channels for the year 2001, showing which channel contributed more total sales per day and category.
WITH sales_union AS (
    SELECT d.d_date AS sale_date,
           i.i_category AS category,
           'Store' AS channel,
           SUM(ss.ss_ext_sales_price) AS sales_amount
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_date, i.i_category

    UNION ALL

    SELECT d.d_date AS sale_date,
           i.i_category AS category,
           'Web' AS channel,
           SUM(ws.ws_ext_sales_price) AS sales_amount
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_date, i.i_category
)
SELECT sale_date,
       category,
       SUM(CASE WHEN channel = 'Store' THEN sales_amount ELSE 0 END) AS store_sales,
       SUM(CASE WHEN channel = 'Web'   THEN sales_amount ELSE 0 END) AS web_sales,
       SUM(sales_amount) AS total_sales,
       CASE WHEN SUM(CASE WHEN channel = 'Store' THEN sales_amount ELSE 0 END) >
                 SUM(CASE WHEN channel = 'Web'   THEN sales_amount ELSE 0 END)
            THEN 'Store' ELSE 'Web' END AS higher_channel
FROM sales_union
GROUP BY sale_date, category
ORDER BY total_sales DESC, sale_date
LIMIT 100
