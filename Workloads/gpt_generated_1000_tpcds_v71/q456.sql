/* goal: Calculate total sales and quantity by sale date and product variant for items whose color starts with 't' and whose name contains a three‑digit code, for the year 2001, while excluding any orders that have a corresponding catalog return. Provide subtotals per date, per product variant, and a grand total. */
WITH sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_order_number,
        i.i_item_sk,
        i.i_color,
        i.i_size,
        i.i_product_name,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        CONCAT(i.i_color, '-', i.i_size) AS product_variant,
        regexp_extract(i.i_product_name, '(\\w+)', 1) AS product_first_word
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE i.i_color LIKE 't%'
      AND regexp_like(i.i_product_name, '\\d{3}')
      AND d.d_year = 2001
)
SELECT
    d.d_date,
    s.product_variant,
    SUM(s.cs_ext_sales_price) AS total_sales,
    SUM(s.cs_quantity) AS total_quantity,
    GROUPING(s.product_variant) AS is_variant_subtotal,
    GROUPING(d.d_date) AS is_date_subtotal
FROM sales s
JOIN date_dim d ON s.cs_sold_date_sk = d.d_date_sk
WHERE NOT EXISTS (
    SELECT 1
    FROM catalog_returns r
    WHERE r.cr_order_number = s.cs_order_number
)
GROUP BY GROUPING SETS (
    (d.d_date, s.product_variant),
    (d.d_date),
    (s.product_variant),
    ()
)
ORDER BY total_sales DESC
LIMIT 100
