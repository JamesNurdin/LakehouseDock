WITH filtered_inventory AS (
    SELECT inv_item_sk, inv_quantity_on_hand
    FROM inventory
    WHERE inv_date_sk = 2450941
),
filtered_sales AS (
    SELECT ws_item_sk, ws_quantity, ws_ext_sales_price, ws_net_paid_inc_tax
    FROM web_sales
    WHERE ws_net_paid_inc_tax > 1000
)
SELECT
    i.i_item_id,
    i.i_product_name,
    i.i_brand,
    i.i_category,
    SUM(fs.ws_ext_sales_price) AS total_sales_price,
    SUM(fs.ws_quantity) AS total_quantity_sold,
    SUM(fi.inv_quantity_on_hand) AS total_inventory_on_hand
FROM filtered_inventory fi
JOIN item i
    ON fi.inv_item_sk = i.i_item_sk
JOIN filtered_sales fs
    ON fs.ws_item_sk = i.i_item_sk
WHERE i.i_current_price > 1.0
GROUP BY i.i_item_id, i.i_product_name, i.i_brand, i.i_category
ORDER BY total_sales_price DESC
LIMIT 10
