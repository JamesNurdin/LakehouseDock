WITH store_part AS (
    SELECT
        d.d_year AS year,
        i.i_category AS category,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
        SUM(DISTINCT ss.ss_quantity) AS distinct_quantity_sum,
        CASE WHEN ss.ss_quantity > 5 THEN 'Large' ELSE 'Small' END AS qty_category,
        (i.i_current_price > (SELECT MAX(i_current_price) FROM item)) AS price_above_max
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND i.i_brand = 'BrandX'
    GROUP BY
        d.d_year,
        i.i_category,
        CASE WHEN ss.ss_quantity > 5 THEN 'Large' ELSE 'Small' END,
        (i.i_current_price > (SELECT MAX(i_current_price) FROM item))
),
catalog_part AS (
    SELECT
        d.d_year AS year,
        i.i_category AS category,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_customers,
        SUM(DISTINCT cs.cs_quantity) AS distinct_quantity_sum,
        CASE WHEN cs.cs_quantity > 5 THEN 'Large' ELSE 'Small' END AS qty_category,
        (i.i_current_price > (SELECT MAX(i_current_price) FROM item)) AS price_above_max
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND i.i_category = 'Sports'
      AND i.i_current_price > (SELECT AVG(i_current_price) FROM item WHERE i_category = 'Sports')
    GROUP BY
        d.d_year,
        i.i_category,
        CASE WHEN cs.cs_quantity > 5 THEN 'Large' ELSE 'Small' END,
        (i.i_current_price > (SELECT MAX(i_current_price) FROM item))
)
SELECT *
FROM (
    SELECT * FROM store_part
    UNION ALL
    SELECT * FROM catalog_part
) t
ORDER BY total_sales DESC
LIMIT 100
