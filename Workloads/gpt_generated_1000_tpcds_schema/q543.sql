WITH intersect_items AS (
    SELECT i.i_item_sk
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE regexp_like(i.i_product_name, '[0-9]{2}')
    INTERSECT
    SELECT i.i_item_sk
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE regexp_like(i.i_product_name, '^.*[A-Z]{3}.*$')
),
union_items AS (
    SELECT i.i_item_sk
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE i.i_category LIKE '%Electronics%'
    UNION
    SELECT i.i_item_sk
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE i.i_category LIKE '%Electronics%'
),
filtered_items AS (
    SELECT i.i_item_sk,
           i.i_product_name,
           CONCAT('Item-', CAST(i.i_item_sk AS VARCHAR)) AS item_key,
           CASE
               WHEN i.i_brand_id = 1 THEN 'BrandA'
               WHEN i.i_brand_id = 2 THEN 'BrandB'
               ELSE 'Other'
           END AS brand_group,
           SUBSTRING(i.i_product_name, 1, 10) AS short_name
    FROM item i
    WHERE i.i_item_sk IN (SELECT i_item_sk FROM intersect_items)
      AND i.i_item_sk IN (SELECT i_item_sk FROM union_items)
)
SELECT d.d_date,
       f.brand_group,
       COUNT(DISTINCT f.i_item_sk) AS distinct_items,
       SUM(cs.cs_net_paid_inc_ship_tax) AS total_sales,
       CASE
           WHEN SUM(cs.cs_net_paid_inc_ship_tax) > 100000 THEN 'Very High'
           WHEN SUM(cs.cs_net_paid_inc_ship_tax) > 50000 THEN 'High'
           ELSE 'Normal'
       END AS sales_category
FROM catalog_sales cs
RIGHT OUTER JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
LEFT JOIN filtered_items f ON cs.cs_item_sk = f.i_item_sk
GROUP BY d.d_date, f.brand_group
ORDER BY total_sales DESC
LIMIT 100
