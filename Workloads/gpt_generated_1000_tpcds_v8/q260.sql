WITH catalog_sales_union AS (
    SELECT DISTINCT
        d.d_year AS year,
        i.i_category AS category,
        cs.cs_order_number AS order_number,
        cs.cs_ext_sales_price AS sales_amount,
        cs.cs_quantity AS quantity,
        EXISTS (
            SELECT 1 FROM catalog_returns cr
            WHERE cr.cr_order_number = cs.cs_order_number
              AND cr.cr_returned_date_sk = d.d_date_sk
        ) AS has_return
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND i.i_category IN ('scanners', 'decor')
),
web_sales_union AS (
    SELECT DISTINCT
        d.d_year AS year,
        i.i_category AS category,
        ws.ws_order_number AS order_number,
        ws.ws_ext_sales_price AS sales_amount,
        ws.ws_quantity AS quantity,
        EXISTS (
            SELECT 1 FROM web_returns wr
            WHERE wr.wr_order_number = ws.ws_order_number
              AND wr.wr_returned_date_sk = d.d_date_sk
        ) AS has_return
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND i.i_category IN ('scanners', 'decor')
),
unioned_sales AS (
    SELECT * FROM catalog_sales_union
    UNION ALL
    SELECT * FROM web_sales_union
),
agg_sales AS (
    SELECT
        year,
        category,
        SUM(sales_amount) AS total_sales,
        COUNT(DISTINCT order_number) AS distinct_orders,
        SUM(CASE WHEN has_return THEN 1 ELSE 0 END) AS orders_with_return
    FROM unioned_sales us
    WHERE EXISTS (
        SELECT 1 FROM catalog_returns cr
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        WHERE cr.cr_order_number = us.order_number
          AND d.d_year = us.year
    )
       OR EXISTS (
        SELECT 1 FROM web_returns wr
        JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
        WHERE wr.wr_order_number = us.order_number
          AND d.d_year = us.year
    )
    GROUP BY ROLLUP (year, category)
)
SELECT
    year,
    category,
    total_sales,
    distinct_orders,
    orders_with_return,
    SUM(total_sales) OVER (PARTITION BY category ORDER BY year
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_sales_category,
    (SELECT AVG(total_sales) FROM agg_sales a2 WHERE a2.category = agg_sales.category) AS avg_sales_per_category
FROM agg_sales
WHERE EXISTS (
    SELECT 1
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE d.d_year = agg_sales.year
      AND i.i_category = agg_sales.category
)
ORDER BY year, category
LIMIT 100
