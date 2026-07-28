WITH recent_dates AS (
    SELECT d_date_sk,
           d_year,
           d_month_seq
    FROM date_dim
    WHERE d_year = 1919
),

catalog_agg AS (
    SELECT
        rd.d_year AS sales_year,
        i.i_category AS category,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        COUNT(*) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY SUM(cs.cs_ext_sales_price) DESC) AS category_rank,
        (SELECT AVG(i2.i_current_price)
         FROM item i2
         WHERE i2.i_category = i.i_category) AS avg_category_price
    FROM catalog_sales cs
    JOIN recent_dates rd ON cs.cs_sold_date_sk = rd.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE i.i_brand = 'Brand#12'
    GROUP BY rd.d_year, i.i_category
),

web_agg AS (
    SELECT
        rd.d_year AS sales_year,
        i.i_category AS category,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(*) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS category_rank,
        (SELECT AVG(i2.i_current_price)
         FROM item i2
         WHERE i2.i_category = i.i_category) AS avg_category_price
    FROM web_sales ws
    JOIN recent_dates rd ON ws.ws_sold_date_sk = rd.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_brand = 'Brand#12'
    GROUP BY rd.d_year, i.i_category
)
SELECT sales_year,
       category,
       total_sales,
       order_count,
       category_rank,
       avg_category_price
FROM catalog_agg
WHERE category_rank <= 5
UNION ALL
SELECT sales_year,
       category,
       total_sales,
       order_count,
       category_rank,
       avg_category_price
FROM web_agg
WHERE category_rank <= 5
ORDER BY sales_year, total_sales DESC
