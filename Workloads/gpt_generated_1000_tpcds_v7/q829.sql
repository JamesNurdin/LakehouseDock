WITH sales_agg AS (
    SELECT
        ws_item_sk,
        ws_sold_date_sk,
        ws_sold_time_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_quantity) AS total_quantity
    FROM web_sales
    WHERE ws_ext_sales_price > 0
    GROUP BY ws_item_sk, ws_sold_date_sk, ws_sold_time_sk
)
SELECT
    i.i_category,
    d.d_year,
    t.t_shift,
    SUM(sa.total_sales) AS category_year_shift_sales,
    AVG(sa.total_quantity) AS avg_quantity_per_sale
FROM sales_agg sa
JOIN item i
    ON sa.ws_item_sk = i.i_item_sk
JOIN date_dim d
    ON sa.ws_sold_date_sk = d.d_date_sk
JOIN time_dim t
    ON sa.ws_sold_time_sk = t.t_time_sk
WHERE d.d_year = 2001
  AND i.i_manufact = 'barprically'
  AND t.t_shift = 'first'
GROUP BY i.i_category, d.d_year, t.t_shift
HAVING SUM(sa.total_sales) > 10000
ORDER BY category_year_shift_sales DESC
LIMIT 10
