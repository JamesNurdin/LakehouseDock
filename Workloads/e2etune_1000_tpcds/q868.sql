WITH aggregated AS (
    SELECT
        i.inv_warehouse_sk,
        r.r_reason_desc,
        COUNT(DISTINCT i.inv_item_sk) AS distinct_items,
        SUM(i.inv_quantity_on_hand) AS total_quantity,
        AVG(wp.wp_image_count) AS avg_image_count,
        SUM(wp.wp_link_count) AS total_links
    FROM inventory i
    JOIN reason r ON i.inv_item_sk = r.r_reason_sk
    JOIN web_page wp ON i.inv_date_sk = wp.wp_creation_date_sk
    WHERE i.inv_quantity_on_hand > 200
      AND wp.wp_type = 'product'
      AND r.r_reason_desc LIKE '%product%'
    GROUP BY i.inv_warehouse_sk, r.r_reason_desc
    HAVING SUM(i.inv_quantity_on_hand) > 500
)
SELECT
    inv_warehouse_sk,
    r_reason_desc,
    distinct_items,
    total_quantity,
    avg_image_count,
    total_links,
    ROW_NUMBER() OVER (PARTITION BY inv_warehouse_sk ORDER BY total_quantity DESC) AS rank_within_warehouse
FROM aggregated
ORDER BY total_quantity DESC
LIMIT 10
