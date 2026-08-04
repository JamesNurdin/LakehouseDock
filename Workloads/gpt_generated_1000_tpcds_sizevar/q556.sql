WITH sampled_store AS (
    SELECT ss_sold_date_sk,
           ss_item_sk,
           ss_sales_price,
           ss_quantity
    FROM store_sales TABLESAMPLE BERNOULLI (10)
),
store_agg AS (
    SELECT d.d_year,
           i.i_category,
           SUM(ss_sales_price * ss_quantity) AS total_sales,
           CASE WHEN SUM(ss_sales_price * ss_quantity) > 100000 THEN 'High' ELSE 'Low' END AS sales_level
    FROM sampled_store ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY ROLLUP (d.d_year, i.i_category)
),
web_agg AS (
    SELECT d.d_year,
           i.i_category,
           SUM(ws_sales_price * ws_quantity) AS total_sales,
           CASE WHEN SUM(ws_sales_price * ws_quantity) > 100000 THEN 'High' ELSE 'Low' END AS sales_level
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND EXISTS (
          SELECT 1
          FROM web_site wsit
          WHERE wsit.web_site_sk = ws.ws_web_site_sk
            AND wsit.web_city = 'Springfield'
      )
    GROUP BY ROLLUP (d.d_year, i.i_category)
),
combined AS (
    SELECT d_year, i_category, total_sales, sales_level FROM store_agg
    UNION ALL
    SELECT d_year, i_category, total_sales, sales_level FROM web_agg
),
filtered AS (
    SELECT *
    FROM combined
    EXCEPT
    SELECT d_year, i_category, total_sales, sales_level
    FROM combined
    WHERE sales_level = 'Low' AND total_sales < 5000
),
ranked AS (
    SELECT d_year,
           i_category,
           total_sales,
           sales_level,
           ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS rn
    FROM filtered
)
SELECT d_year,
       i_category,
       total_sales,
       sales_level
FROM ranked
WHERE rn <= 5
ORDER BY d_year, total_sales DESC
LIMIT 100
