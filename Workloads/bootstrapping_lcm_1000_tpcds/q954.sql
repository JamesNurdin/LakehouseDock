WITH date_inventory AS (
    SELECT
        inv.inv_quantity_on_hand,
        inv.inv_warehouse_sk,
        inv.inv_item_sk,
        inv.inv_date_sk,
        d.d_date,
        d.d_year,
        d.d_month_seq,
        d.d_current_month,
        d.d_week_seq,
        d.d_dow,
        i.i_item_id,
        i.i_product_name,
        i.i_category,
        i.i_brand,
        i.i_wholesale_cost,
        i.i_current_price,
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        s.s_city,
        s.s_closed_date_sk
    FROM inventory inv
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
),
page_creation AS (
    SELECT
        d.d_date_sk,
        COUNT(DISTINCT wp.wp_web_page_id) AS pages_created,
        SUM(wp.wp_image_count) AS total_images_created,
        SUM(wp.wp_char_count) AS total_chars_created
    FROM date_dim d
    JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
    GROUP BY d.d_date_sk
),
page_access AS (
    SELECT
        d.d_date_sk,
        COUNT(DISTINCT wp.wp_web_page_id) AS pages_accessed,
        SUM(wp.wp_link_count) AS total_links_accessed,
        SUM(wp.wp_char_count) AS total_chars_accessed
    FROM date_dim d
    JOIN web_page wp ON wp.wp_access_date_sk = d.d_date_sk
    GROUP BY d.d_date_sk
),
page_metrics AS (
    SELECT
        COALESCE(pc.d_date_sk, pa.d_date_sk) AS d_date_sk,
        COALESCE(pc.pages_created, 0) AS pages_created,
        COALESCE(pa.pages_accessed, 0) AS pages_accessed,
        COALESCE(pc.total_images_created, 0) AS total_images_created,
        COALESCE(pc.total_chars_created, 0) AS total_chars_created,
        COALESCE(pa.total_links_accessed, 0) AS total_links_accessed,
        COALESCE(pa.total_chars_accessed, 0) AS total_chars_accessed
    FROM page_creation pc
    FULL OUTER JOIN page_access pa ON pc.d_date_sk = pa.d_date_sk
)
SELECT
    di.s_store_id,
    di.s_store_name,
    di.s_state,
    di.s_city,
    di.d_year,
    di.d_current_month,
    di.i_category,
    di.i_brand,
    SUM(di.inv_quantity_on_hand) AS total_qty_on_hand,
    AVG(di.i_wholesale_cost) AS avg_wholesale_cost,
    MAX(di.i_current_price) AS max_current_price,
    pm.pages_created,
    pm.pages_accessed,
    pm.total_images_created,
    pm.total_links_accessed,
    ROW_NUMBER() OVER (PARTITION BY di.s_state ORDER BY SUM(di.inv_quantity_on_hand) DESC) AS store_rank_in_state
FROM date_inventory di
LEFT JOIN page_metrics pm ON di.inv_date_sk = pm.d_date_sk
GROUP BY
    di.s_store_id,
    di.s_store_name,
    di.s_state,
    di.s_city,
    di.d_year,
    di.d_current_month,
    di.i_category,
    di.i_brand,
    pm.pages_created,
    pm.pages_accessed,
    pm.total_images_created,
    pm.total_links_accessed
HAVING SUM(di.inv_quantity_on_hand) > 0
ORDER BY total_qty_on_hand DESC
LIMIT 100
