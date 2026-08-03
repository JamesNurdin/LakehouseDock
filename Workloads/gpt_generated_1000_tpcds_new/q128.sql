WITH sold_items AS (
    SELECT DISTINCT cs_item_sk
    FROM catalog_sales
    WHERE regexp_like(cast(cs_order_number AS varchar), '^1[0-9]{5}$')
      AND cs_net_paid > (
          SELECT MAX(cs_net_paid)
          FROM catalog_sales
          WHERE cs_sold_date_sk = 2450955
      )
),
available_items AS (
    SELECT DISTINCT inv_item_sk
    FROM inventory
    WHERE inv_quantity_on_hand > 0
),
filtered_items AS (
    SELECT cs_item_sk
    FROM sold_items
    EXCEPT
    SELECT inv_item_sk FROM available_items
)
SELECT
    i.i_item_id,
    i.i_product_name,
    COUNT(cs.cs_order_number) AS orders_cnt,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    regexp_extract(i.i_product_name, '(\\w+)\\s+(\\w+)', 1) AS first_word,
    CONCAT(i.i_color, '-', ship.sm_ship_mode_id) AS color_ship_combo
FROM catalog_sales cs
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN ship_mode ship ON cs.cs_ship_mode_sk = ship.sm_ship_mode_sk
JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
JOIN filtered_items f ON cs.cs_item_sk = f.cs_item_sk
WHERE i.i_color LIKE 'b%'
  AND regexp_like(i.i_product_name, '.*(Portable|Deluxe).*')
GROUP BY
    i.i_item_id,
    i.i_product_name,
    regexp_extract(i.i_product_name, '(\\w+)\\s+(\\w+)', 1),
    CONCAT(i.i_color, '-', ship.sm_ship_mode_id)
ORDER BY total_sales DESC
LIMIT 100
