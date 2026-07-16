SELECT
    cp.cp_catalog_page_id,
    cp.cp_catalog_page_number,
    cp.cp_type,
    start_d.d_date AS start_date,
    end_d.d_date AS end_date,
    inv.inv_quantity_on_hand,
    inv.inv_item_sk,
    s.s_store_name,
    s.s_city,
    s.s_state,
    s.s_store_id,
    wp.wp_url,
    wp.wp_type,
    creation_d.d_date AS creation_date,
    access_d.d_date AS access_date,
    CASE
        WHEN inv.inv_quantity_on_hand > 100 THEN 'HIGH'
        WHEN inv.inv_quantity_on_hand > 0 THEN 'LOW'
        ELSE 'NONE'
    END AS inventory_status,
    (inv.inv_quantity_on_hand * 1.0) / NULLIF(s.s_floor_space, 0) AS qty_per_sqft,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY inv.inv_quantity_on_hand DESC) AS inventory_rank
FROM catalog_page cp
JOIN date_dim start_d
    ON cp.cp_start_date_sk = start_d.d_date_sk
JOIN date_dim end_d
    ON cp.cp_end_date_sk = end_d.d_date_sk
JOIN inventory inv
    ON inv.inv_date_sk = start_d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = end_d.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = start_d.d_date_sk
JOIN date_dim creation_d
    ON wp.wp_creation_date_sk = creation_d.d_date_sk
JOIN date_dim access_d
    ON wp.wp_access_date_sk = access_d.d_date_sk
WHERE cp.cp_type = 'Catalog'
  AND s.s_state = 'CA'
ORDER BY cp.cp_catalog_page_number DESC
LIMIT 100
