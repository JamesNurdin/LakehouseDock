WITH agg AS (
    SELECT
        d.d_quarter_name,
        wp.wp_type,
        SUM(i.inv_quantity_on_hand) AS total_inventory_qty,
        AVG(wp.wp_image_count) AS avg_image_count,
        COUNT(DISTINCT wp.wp_web_page_id) AS distinct_page_cnt
    FROM inventory i
    JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
    WHERE d.d_holiday = 'Y'
      AND wp.wp_type IN ('article', 'blog')
      AND d.d_year BETWEEN 2020 AND 2022
    GROUP BY d.d_quarter_name, wp.wp_type
    HAVING SUM(i.inv_quantity_on_hand) > 1000
)
SELECT
    a.d_quarter_name,
    a.wp_type,
    a.total_inventory_qty,
    a.avg_image_count,
    a.distinct_page_cnt,
    RANK() OVER (ORDER BY a.total_inventory_qty DESC) AS inventory_qty_rank
FROM agg a
ORDER BY a.total_inventory_qty DESC
LIMIT 50
