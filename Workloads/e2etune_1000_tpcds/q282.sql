WITH inv_agg AS (
    SELECT inv_date_sk,
           inv_warehouse_sk,
           SUM(inv_quantity_on_hand) AS total_qty,
           COUNT(DISTINCT inv_item_sk) AS distinct_items
    FROM inventory
    WHERE inv_quantity_on_hand > 0
    GROUP BY inv_date_sk, inv_warehouse_sk
),
cp_agg AS (
    SELECT cp_start_date_sk AS date_sk,
           cp_type,
           cp_department,
           COUNT(*) AS page_count,
           AVG(cp_catalog_page_number) AS avg_page_num
    FROM catalog_page
    WHERE cp_type IN ('monthly', 'quarterly')
    GROUP BY cp_start_date_sk, cp_type, cp_department
),
wp_agg AS (
    SELECT wp_creation_date_sk AS date_sk,
           wp_type,
           SUM(wp_char_count) AS total_chars,
           AVG(wp_image_count) AS avg_images,
           COUNT(*) AS page_views
    FROM web_page
    WHERE wp_type IS NOT NULL
    GROUP BY wp_creation_date_sk, wp_type
)
SELECT
    cp.date_sk,
    cp.cp_type,
    cp.cp_department,
    inv.inv_warehouse_sk,
    inv.total_qty,
    inv.distinct_items,
    wp.wp_type,
    wp.total_chars,
    wp.avg_images,
    wp.page_views,
    hd.avg_vehicle_count,
    RANK() OVER (PARTITION BY cp.cp_type ORDER BY inv.total_qty DESC) AS warehouse_rank
FROM cp_agg cp
JOIN inv_agg inv ON cp.date_sk = inv.inv_date_sk
JOIN wp_agg wp ON cp.date_sk = wp.date_sk
CROSS JOIN (
    SELECT AVG(hd_vehicle_count) AS avg_vehicle_count
    FROM household_demographics
    WHERE hd_buy_potential = 'High'
) hd
WHERE inv.total_qty > 1000
ORDER BY inv.total_qty DESC
LIMIT 100
