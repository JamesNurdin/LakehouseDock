/*
  Goal: Compare daily catalog sales and returns for the year 2001, compute a running total of sales per item, show the previous day's sales amount, expand item attributes (units and color) via UNNEST, and then exclude any rows that also appear in 2002 sales.
*/
WITH sales AS (
    SELECT
        d.d_date AS sale_date,
        cs.cs_item_sk,
        i.i_category,
        cs.cs_ext_sales_price,
        SUM(cs.cs_ext_sales_price) OVER (PARTITION BY cs.cs_item_sk ORDER BY d.d_date
                                          ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_sales,
        LAG(cs.cs_ext_sales_price) OVER (PARTITION BY cs.cs_item_sk ORDER BY d.d_date) AS prev_day_sales,
        (SELECT MAX(d2.d_date) FROM date_dim d2 WHERE d2.d_year = 2001) AS max_year_date,
        attr
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    CROSS JOIN UNNEST(ARRAY[i.i_units, i.i_color]) AS t(attr)
    WHERE d.d_year = 2001
      AND cs.cs_item_sk IN (SELECT i2.i_item_sk FROM item i2 WHERE i2.i_wholesale_cost > 1.0)
),
returns AS (
    SELECT
        d.d_date AS sale_date,
        cr.cr_item_sk AS cs_item_sk,
        i.i_category,
        cr.cr_return_amount * -1 AS cs_ext_sales_price,
        CAST(NULL AS decimal(7,2)) AS running_total_sales,
        CAST(NULL AS decimal(7,2)) AS prev_day_sales,
        CAST(NULL AS date) AS max_year_date,
        attr
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    CROSS JOIN UNNEST(ARRAY[i.i_units, i.i_color]) AS t(attr)
    WHERE d.d_year = 2001
      AND cr.cr_item_sk IN (SELECT i2.i_item_sk FROM item i2 WHERE i2.i_wholesale_cost > 1.0)
),
combined AS (
    SELECT * FROM sales
    UNION
    SELECT * FROM returns
),
exclude_set AS (
    SELECT
        d.d_date AS sale_date,
        cs.cs_item_sk,
        i.i_category,
        cs.cs_ext_sales_price,
        CAST(NULL AS decimal(7,2)) AS running_total_sales,
        CAST(NULL AS decimal(7,2)) AS prev_day_sales,
        CAST(NULL AS date) AS max_year_date,
        CAST(NULL AS varchar) AS attr
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year = 2002
)
SELECT *
FROM combined
EXCEPT
SELECT *
FROM exclude_set
ORDER BY sale_date DESC
LIMIT 100
