WITH promoted_items AS (
    SELECT DISTINCT p.p_item_sk
    FROM promotion p
    WHERE p.p_discount_active = 'Y' AND p.p_cost > 0
)
SELECT
    cp.cp_catalog_page_id,
    d.d_year,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    REGEXP_EXTRACT(i.i_product_name, '(\\d{3})') AS extracted_code,
    CONCAT(cp.cp_type, '_', SUBSTRING(i.i_color, 1, 3)) AS page_type_color_prefix
FROM catalog_sales cs
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
WHERE
    REGEXP_LIKE(i.i_product_name, '[A-Z]{2}\\d{3}')
    AND cp.cp_description LIKE '%special%'
    AND cs.cs_item_sk IN (SELECT p_item_sk FROM promoted_items)
    AND d.d_year = 2001
GROUP BY
    cp.cp_catalog_page_id,
    d.d_year,
    cp.cp_type,
    i.i_color,
    i.i_product_name
ORDER BY total_sales DESC
LIMIT 100
