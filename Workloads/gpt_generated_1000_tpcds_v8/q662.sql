WITH common_items AS (
    SELECT cs.cs_item_sk AS item_sk
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE regexp_like(i.i_product_name, '^.*[A-Z]{2}[0-9]{2}.*$')
    INTERSECT
    SELECT ws.ws_item_sk
    FROM web_sales ws
    JOIN item i2 ON ws.ws_item_sk = i2.i_item_sk
    WHERE i2.i_product_name LIKE '%Special%'
)
SELECT
    i.i_item_id,
    i.i_product_name,
    CONCAT('Category: ', i.i_category) AS category_label,
    regexp_extract(i.i_product_name, '(\\d{3})', 1) AS code_extracted,
    (
        SELECT SUM(cs2.cs_quantity)
        FROM catalog_sales cs2
        WHERE cs2.cs_item_sk = i.i_item_sk
    ) AS total_catalog_quantity,
    (
        SELECT COUNT(DISTINCT cs2.cs_bill_customer_sk)
        FROM catalog_sales cs2
        WHERE cs2.cs_item_sk = i.i_item_sk
    ) AS distinct_customers,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders
FROM catalog_sales cs
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND i.i_product_name LIKE '%Blue%'
  AND regexp_like(i.i_product_name, '^.*[A-Z]{2}[0-9]{2}.*$')
  AND i.i_item_sk IN (SELECT item_sk FROM common_items)
GROUP BY i.i_item_id, i.i_product_name, i.i_category, i.i_item_sk

UNION DISTINCT

SELECT
    i2.i_item_id,
    i2.i_product_name,
    CONCAT('Category: ', i2.i_category) AS category_label,
    regexp_extract(i2.i_product_name, '(\\d{3})', 1) AS code_extracted,
    (
        SELECT SUM(ws2.ws_quantity)
        FROM web_sales ws2
        WHERE ws2.ws_item_sk = i2.i_item_sk
    ) AS total_web_quantity,
    (
        SELECT COUNT(DISTINCT ws2.ws_bill_customer_sk)
        FROM web_sales ws2
        WHERE ws2.ws_item_sk = i2.i_item_sk
    ) AS distinct_customers,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders
FROM web_sales ws
JOIN item i2 ON ws.ws_item_sk = i2.i_item_sk
JOIN date_dim d2 ON ws.ws_sold_date_sk = d2.d_date_sk
WHERE d2.d_year = 2001
  AND i2.i_product_name LIKE '%Red%'
  AND regexp_like(i2.i_product_name, '^.*[A-Z]{2}[0-9]{2}.*$')
  AND i2.i_item_sk IN (SELECT item_sk FROM common_items)
GROUP BY i2.i_item_id, i2.i_product_name, i2.i_category, i2.i_item_sk

ORDER BY total_sales DESC
OFFSET 10 ROWS
LIMIT 100
