WITH
    inv_agg AS (
        SELECT
            inv_date_sk,
            SUM(inv_quantity_on_hand) AS total_inventory
        FROM inventory
        GROUP BY inv_date_sk
    ),
    cp_start_agg AS (
        SELECT
            cp_start_date_sk,
            COUNT(DISTINCT cp_catalog_page_id) AS start_page_cnt
        FROM catalog_page
        GROUP BY cp_start_date_sk
    ),
    cp_end_agg AS (
        SELECT
            cp_end_date_sk,
            COUNT(DISTINCT cp_catalog_page_id) AS end_page_cnt
        FROM catalog_page
        GROUP BY cp_end_date_sk
    ),
    wp_creation_agg AS (
        SELECT
            wp_creation_date_sk,
            COUNT(DISTINCT wp_web_page_id) AS created_page_cnt
        FROM web_page
        GROUP BY wp_creation_date_sk
    ),
    wp_access_agg AS (
        SELECT
            wp_access_date_sk,
            COUNT(DISTINCT wp_web_page_id) AS accessed_page_cnt
        FROM web_page
        GROUP BY wp_access_date_sk
    )
SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d.d_date AS store_closed_date,
    COALESCE(i.total_inventory, 0) AS total_inventory_on_closed_date,
    COALESCE(cs.start_page_cnt, 0) AS catalog_pages_started,
    COALESCE(ce.end_page_cnt, 0) AS catalog_pages_ended,
    COALESCE(wc.created_page_cnt, 0) AS web_pages_created,
    COALESCE(wa.accessed_page_cnt, 0) AS web_pages_accessed,
    CASE
        WHEN COALESCE(wc.created_page_cnt, 0) > 0
        THEN COALESCE(i.total_inventory, 0) / COALESCE(wc.created_page_cnt, 0)
        ELSE NULL
    END AS inventory_per_created_page,
    CASE
        WHEN COALESCE(cs.start_page_cnt, 0) > 0
        THEN COALESCE(i.total_inventory, 0) / COALESCE(cs.start_page_cnt, 0)
        ELSE NULL
    END AS inventory_per_started_catalog
FROM store s
JOIN date_dim d
    ON s.s_closed_date_sk = d.d_date_sk
LEFT JOIN inv_agg i
    ON i.inv_date_sk = d.d_date_sk
LEFT JOIN cp_start_agg cs
    ON cs.cp_start_date_sk = d.d_date_sk
LEFT JOIN cp_end_agg ce
    ON ce.cp_end_date_sk = d.d_date_sk
LEFT JOIN wp_creation_agg wc
    ON wc.wp_creation_date_sk = d.d_date_sk
LEFT JOIN wp_access_agg wa
    ON wa.wp_access_date_sk = d.d_date_sk
WHERE d.d_year = 2022
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d.d_date,
    i.total_inventory,
    cs.start_page_cnt,
    ce.end_page_cnt,
    wc.created_page_cnt,
    wa.accessed_page_cnt
ORDER BY total_inventory_on_closed_date DESC
LIMIT 100
