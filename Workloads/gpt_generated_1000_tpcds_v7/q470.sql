/*
  Goal: Combine total sales from brick‑and‑mortar stores and the web site for the year 1998, grouped by item category and sales channel, and return the top rows ordered by year, category and channel.
*/
WITH store_totals AS (
    SELECT
        d.d_year AS sales_year,
        i.i_category AS item_category,
        SUM(ss.ss_net_paid) AS total_sales,
        'store' AS sales_channel
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 1998
    GROUP BY d.d_year, i.i_category
),
web_totals AS (
    SELECT
        d.d_year AS sales_year,
        i.i_category AS item_category,
        SUM(ws.ws_net_paid) AS total_sales,
        'web' AS sales_channel
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = 1998
    GROUP BY d.d_year, i.i_category
)
SELECT
    sales_year,
    item_category,
    total_sales,
    sales_channel
FROM (
    SELECT sales_year, item_category, total_sales, sales_channel FROM store_totals
    UNION ALL
    SELECT sales_year, item_category, total_sales, sales_channel FROM web_totals
) AS combined
ORDER BY sales_year, item_category, sales_channel
LIMIT 100
