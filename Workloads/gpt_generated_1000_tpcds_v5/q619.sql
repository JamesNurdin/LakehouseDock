WITH sales_brand_a AS (
    SELECT
        i.i_brand AS brand,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT i.i_product_name) AS distinct_products
    FROM tpcds.web_sales ws
    JOIN tpcds.item i
        ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_manager_id = 18
      AND ws.ws_wholesale_cost > 50
      AND i.i_rec_start_date >= DATE '1999-01-01'
      AND i.i_rec_start_date < DATE '2001-01-01'
    GROUP BY i.i_brand
),
sales_brand_b AS (
    SELECT
        i.i_brand AS brand,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT i.i_product_name) AS distinct_products
    FROM tpcds.web_sales ws
    JOIN tpcds.item i
        ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_manager_id = 6
      AND ws.ws_wholesale_cost <= 50
      AND i.i_rec_start_date >= DATE '2001-01-01'
      AND i.i_rec_start_date < DATE '2003-01-01'
    GROUP BY i.i_brand
)
SELECT brand,
       total_sales,
       distinct_products
FROM sales_brand_a
UNION
SELECT brand,
       total_sales,
       distinct_products
FROM sales_brand_b
ORDER BY total_sales DESC
