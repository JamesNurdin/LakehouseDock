WITH filtered_items AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        i.i_item_desc,
        i.i_category,
        i.i_brand,
        regexp_extract(i.i_item_desc, '(\\d{4})', 1) AS extracted_year,
        CASE
            WHEN regexp_like(i.i_item_desc, '(?i)fresh|organic') THEN 'Health'
            ELSE 'Other'
        END AS health_flag,
        concat(i.i_item_id, '-', i.i_brand) AS item_brand_code
    FROM tpcds.item i
    WHERE i.i_item_desc IS NOT NULL
      AND regexp_like(i.i_item_desc, '\\d{4}')
      AND i.i_product_name LIKE '%COCOA%'
)
SELECT
    f.i_item_id,
    f.i_product_name,
    f.item_brand_code,
    f.health_flag,
    SUM(cr.cr_return_amount) AS total_return_amount,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
    SUM(CASE WHEN p.p_discount_active = 'Y' THEN cr.cr_return_amount * 0.9 ELSE cr.cr_return_amount END) AS adjusted_return_amount,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand
FROM filtered_items f
JOIN tpcds.catalog_returns cr ON cr.cr_item_sk = f.i_item_sk
JOIN tpcds.inventory inv ON inv.inv_item_sk = f.i_item_sk
LEFT JOIN tpcds.promotion p ON p.p_item_sk = f.i_item_sk
WHERE inv.inv_quantity_on_hand > 0
  AND p.p_channel_radio = 'Y'
GROUP BY
    f.i_item_id,
    f.i_product_name,
    f.item_brand_code,
    f.health_flag
ORDER BY total_return_amount DESC
LIMIT 100
