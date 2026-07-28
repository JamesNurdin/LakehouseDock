WITH filtered_sales AS (
    SELECT
        cs.cs_order_number AS order_number,
        cs.cs_ext_sales_price AS ext_sales_price,
        i.i_item_desc AS item_desc,
        i.i_product_name AS product_name,
        sm.sm_carrier AS carrier,
        sm.sm_code AS ship_code
    FROM tpcds.catalog_sales cs
    JOIN tpcds.item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN tpcds.ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE regexp_like(i.i_item_desc, '[A-Z]{2,}[0-9]{2,}')
      AND sm.sm_code LIKE 'A%'
)
SELECT
    carrier,
    regexp_extract(product_name, '([^\-]+)-\d+$', 1) AS product_prefix,
    SUM(ext_sales_price) AS total_ext_sales,
    COUNT(DISTINCT order_number) AS unique_orders
FROM filtered_sales
GROUP BY carrier, regexp_extract(product_name, '([^\-]+)-\d+$', 1)
HAVING SUM(ext_sales_price) > 5000
ORDER BY total_ext_sales DESC
LIMIT 5
