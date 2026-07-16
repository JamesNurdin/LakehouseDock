SELECT
    d_i.d_year,
    d_i.d_quarter_seq,
    s.s_state,
    wp.wp_type,
    CASE
        WHEN i.inv_quantity_on_hand > 1000 THEN 'HIGH'
        WHEN i.inv_quantity_on_hand > 500 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS inventory_category,
    SUM(i.inv_quantity_on_hand) AS total_inventory_quantity,
    COUNT(DISTINCT wp.wp_web_page_sk) AS distinct_web_pages,
    AVG(wp.wp_image_count) AS avg_image_count,
    SUM(wp.wp_image_count) AS total_image_count,
    MIN(i.inv_quantity_on_hand) AS min_inventory_quantity,
    MAX(i.inv_quantity_on_hand) AS max_inventory_quantity,
    COUNT(CASE WHEN d_a.d_week_seq = d_i.d_week_seq THEN 1 END) AS pages_accessed_same_week
FROM inventory i
JOIN date_dim d_i ON i.inv_date_sk = d_i.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_i.d_date_sk
JOIN web_page wp ON wp.wp_creation_date_sk = d_i.d_date_sk
JOIN date_dim d_a ON wp.wp_access_date_sk = d_a.d_date_sk
WHERE d_i.d_year BETWEEN 2018 AND 2022
GROUP BY
    d_i.d_year,
    d_i.d_quarter_seq,
    s.s_state,
    wp.wp_type,
    CASE
        WHEN i.inv_quantity_on_hand > 1000 THEN 'HIGH'
        WHEN i.inv_quantity_on_hand > 500 THEN 'MEDIUM'
        ELSE 'LOW'
    END
HAVING SUM(i.inv_quantity_on_hand) > 500
ORDER BY total_inventory_quantity DESC
LIMIT 200
