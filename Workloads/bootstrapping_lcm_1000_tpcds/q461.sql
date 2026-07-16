WITH agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        s.s_state,
        w.w_country,
        d_access.d_day_name,
        SUM(i.inv_quantity_on_hand) AS total_inventory,
        COUNT(DISTINCT i.inv_item_sk) AS distinct_items,
        AVG(i.inv_quantity_on_hand) AS avg_inventory_per_item,
        SUM(p.wp_image_count) AS total_images,
        SUM(p.wp_link_count) AS total_links,
        SUM(p.wp_char_count) AS total_chars,
        COUNT(DISTINCT p.wp_web_page_id) AS distinct_pages
    FROM date_dim d
    JOIN inventory i
        ON i.inv_date_sk = d.d_date_sk
    JOIN warehouse w
        ON i.inv_warehouse_sk = w.w_warehouse_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    JOIN web_page p
        ON p.wp_creation_date_sk = d.d_date_sk
    JOIN date_dim d_access
        ON p.wp_access_date_sk = d_access.d_date_sk
    WHERE d.d_year = 2021
    GROUP BY
        d.d_year,
        d.d_month_seq,
        s.s_state,
        w.w_country,
        d_access.d_day_name
)
SELECT
    a.d_year,
    a.d_month_seq,
    a.s_state,
    a.w_country,
    a.d_day_name,
    a.total_inventory,
    a.distinct_items,
    a.avg_inventory_per_item,
    a.total_images,
    a.total_links,
    a.total_chars,
    a.distinct_pages,
    ROW_NUMBER() OVER (PARTITION BY a.s_state ORDER BY a.total_inventory DESC) AS rank_by_inventory_state
FROM agg a
ORDER BY a.total_inventory DESC
LIMIT 50
