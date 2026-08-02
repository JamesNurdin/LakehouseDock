/* Goal: Compare yearly sales and order counts across catalog, store, and web channels versus catalog returns for the year 2000, using full outer joins and a UNION ALL to combine two sets of channel comparisons. */
WITH cat AS (
    SELECT 
        d.d_year AS year,
        i.i_category AS category,
        SUM(cs.cs_net_paid) AS total_sales,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year = 2000
    GROUP BY d.d_year, i.i_category
),
store AS (
    SELECT 
        d.d_year AS year,
        i.i_category AS category,
        SUM(ss.ss_net_paid) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS order_cnt
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2000
    GROUP BY d.d_year, i.i_category
),
web AS (
    SELECT 
        d.d_year AS year,
        i.i_category AS category,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = 2000
    GROUP BY d.d_year, i.i_category
),
cr AS (
    SELECT 
        d.d_year AS year,
        i.i_category AS category,
        SUM(cr.cr_net_loss) AS total_sales,
        COUNT(DISTINCT cr.cr_order_number) AS order_cnt
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE d.d_year = 2000
    GROUP BY d.d_year, i.i_category
)
SELECT
    COALESCE(cat.year, store.year) AS year,
    COALESCE(cat.category, store.category) AS category,
    COALESCE(cat.total_sales, 0) AS sales_a,
    COALESCE(store.total_sales, 0) AS sales_b,
    COALESCE(cat.order_cnt, 0) AS orders_a,
    COALESCE(store.order_cnt, 0) AS orders_b
FROM cat
FULL OUTER JOIN store
    ON cat.year = store.year AND cat.category = store.category

UNION ALL

SELECT
    COALESCE(web.year, cr.year) AS year,
    COALESCE(web.category, cr.category) AS category,
    COALESCE(web.total_sales, 0) AS sales_a,
    COALESCE(cr.total_sales, 0) AS sales_b,
    COALESCE(web.order_cnt, 0) AS orders_a,
    COALESCE(cr.order_cnt, 0) AS orders_b
FROM web
FULL OUTER JOIN cr
    ON web.year = cr.year AND web.category = cr.category

LIMIT 100
