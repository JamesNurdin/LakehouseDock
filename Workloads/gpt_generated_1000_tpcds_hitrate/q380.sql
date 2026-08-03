WITH sales_union AS (
    SELECT i.i_category AS category,
           td.t_hour AS hour,
           ws.ws_ext_sales_price AS sales_amount
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    WHERE ws.ws_ext_sales_price > 0

    UNION ALL

    SELECT i.i_category AS category,
           td.t_hour AS hour,
           ss.ss_ext_sales_price AS sales_amount
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE ss.ss_ext_sales_price > 0
)
SELECT
    category,
    hour,
    SUM(sales_amount) AS total_sales,
    (
        SELECT COALESCE(SUM(cr.cr_return_amount), 0)
        FROM catalog_returns cr
        JOIN item i2 ON cr.cr_item_sk = i2.i_item_sk
        JOIN time_dim td2 ON cr.cr_returned_time_sk = td2.t_time_sk
        WHERE i2.i_category = category
          AND td2.t_hour = hour
    ) AS total_returns
FROM sales_union
GROUP BY ROLLUP (category, hour)
HAVING (category IS NULL) OR (SUM(sales_amount) > 1000)
ORDER BY category, hour
LIMIT 100
