WITH sales_items AS (
   SELECT DISTINCT cs.cs_item_sk AS item_sk
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   WHERE d.d_year = 2001
     AND regexp_like(i.i_item_desc, '.*[A-Z]{2}[0-9]{3}.*')
     AND i.i_product_name LIKE '%Deluxe%'
),
returns_items AS (
   SELECT DISTINCT cr.cr_item_sk AS item_sk
   FROM catalog_returns cr
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN item i ON cr.cr_item_sk = i.i_item_sk
   WHERE d.d_year = 2001
     AND regexp_like(i.i_item_desc, '.*[A-Z]{2}[0-9]{3}.*')
     AND i.i_product_name LIKE '%Deluxe%'
),
intersect_items AS (
   SELECT item_sk FROM sales_items
   INTERSECT
   SELECT item_sk FROM returns_items
)
SELECT
    i.i_item_sk,
    i.i_product_name || ' - ' || i.i_color AS product_label,
    regexp_extract(i.i_item_desc, '([A-Z]{2}[0-9]{3})', 1) AS extracted_code,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(cr.cr_return_amount) AS total_returns,
    CASE
        WHEN SUM(cs.cs_net_paid) - SUM(cr.cr_return_amount) > 0 THEN 'Net Positive'
        ELSE 'Net Non-Positive'
    END AS net_status,
    promo.p_promo_name,
    SUBSTRING(i.i_item_desc FROM 1 FOR 30) AS item_desc_prefix
FROM intersect_items ii
JOIN catalog_sales cs ON ii.item_sk = cs.cs_item_sk
JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number AND cr.cr_item_sk = cs.cs_item_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
LEFT JOIN LATERAL (
    SELECT p.p_promo_name
    FROM promotion p
    WHERE p.p_item_sk = i.i_item_sk
    ORDER BY p.p_start_date_sk DESC
    LIMIT 1
) promo ON true
WHERE EXISTS (
    SELECT 1 FROM promotion p2
    WHERE p2.p_item_sk = i.i_item_sk AND p2.p_discount_active = 'Y'
)
GROUP BY
    i.i_item_sk,
    i.i_product_name,
    i.i_color,
    regexp_extract(i.i_item_desc, '([A-Z]{2}[0-9]{3})', 1),
    promo.p_promo_name,
    i.i_item_desc
ORDER BY total_sales DESC
LIMIT 100
