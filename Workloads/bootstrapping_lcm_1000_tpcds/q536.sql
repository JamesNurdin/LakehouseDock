WITH promo_dates AS (
    SELECT
        p.p_promo_id,
        p.p_promo_name,
        p.p_cost,
        d_start.d_date AS start_date,
        d_start.d_year AS start_year,
        d_start.d_quarter_name AS start_quarter,
        d_end.d_date AS end_date,
        d_end.d_year AS end_year,
        d_end.d_quarter_name AS end_quarter
    FROM promotion p
    JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end   ON p.p_end_date_sk   = d_end.d_date_sk
),
inv_start_agg AS (
    SELECT
        p.p_promo_id,
        SUM(i.inv_quantity_on_hand) AS total_inventory_start
    FROM promotion p
    JOIN date_dim d ON p.p_start_date_sk = d.d_date_sk
    JOIN inventory i ON i.inv_date_sk = d.d_date_sk
    GROUP BY p.p_promo_id
),
inv_end_agg AS (
    SELECT
        p.p_promo_id,
        SUM(i.inv_quantity_on_hand) AS total_inventory_end
    FROM promotion p
    JOIN date_dim d ON p.p_end_date_sk = d.d_date_sk
    JOIN inventory i ON i.inv_date_sk = d.d_date_sk
    GROUP BY p.p_promo_id
),
store_closed_start_agg AS (
    SELECT
        p.p_promo_id,
        COUNT(s.s_store_sk) AS stores_closed_start
    FROM promotion p
    JOIN date_dim d ON p.p_start_date_sk = d.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    GROUP BY p.p_promo_id
),
store_closed_end_agg AS (
    SELECT
        p.p_promo_id,
        COUNT(s.s_store_sk) AS stores_closed_end
    FROM promotion p
    JOIN date_dim d ON p.p_end_date_sk = d.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    GROUP BY p.p_promo_id
),
web_page_created_agg AS (
    SELECT
        p.p_promo_id,
        COUNT(wp.wp_web_page_sk) AS web_pages_created_start,
        AVG(wp.wp_image_count)   AS avg_image_count_start
    FROM promotion p
    JOIN date_dim d ON p.p_start_date_sk = d.d_date_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
    GROUP BY p.p_promo_id
),
web_page_access_agg AS (
    SELECT
        p.p_promo_id,
        COUNT(wp.wp_web_page_sk) AS web_pages_accessed_end,
        AVG(wp.wp_link_count)    AS avg_link_count_end
    FROM promotion p
    JOIN date_dim d ON p.p_end_date_sk = d.d_date_sk
    JOIN web_page wp ON wp.wp_access_date_sk = d.d_date_sk
    GROUP BY p.p_promo_id
)
SELECT
    pd.p_promo_id,
    pd.p_promo_name,
    pd.p_cost,
    pd.start_date,
    pd.start_year,
    pd.start_quarter,
    pd.end_date,
    pd.end_year,
    pd.end_quarter,
    COALESCE(isag.total_inventory_start, 0)   AS total_inventory_start,
    COALESCE(ieag.total_inventory_end,   0)   AS total_inventory_end,
    COALESCE(ssag.stores_closed_start, 0)     AS stores_closed_start,
    COALESCE(seag.stores_closed_end,   0)     AS stores_closed_end,
    COALESCE(wcag.web_pages_created_start, 0) AS web_pages_created_start,
    COALESCE(wcag.avg_image_count_start,   0) AS avg_image_count_start,
    COALESCE(waag.web_pages_accessed_end, 0) AS web_pages_accessed_end,
    COALESCE(waag.avg_link_count_end,     0) AS avg_link_count_end
FROM promo_dates pd
LEFT JOIN inv_start_agg        isag ON pd.p_promo_id = isag.p_promo_id
LEFT JOIN inv_end_agg          ieag ON pd.p_promo_id = ieag.p_promo_id
LEFT JOIN store_closed_start_agg ssag ON pd.p_promo_id = ssag.p_promo_id
LEFT JOIN store_closed_end_agg   seag ON pd.p_promo_id = seag.p_promo_id
LEFT JOIN web_page_created_agg   wcag ON pd.p_promo_id = wcag.p_promo_id
LEFT JOIN web_page_access_agg    waag ON pd.p_promo_id = waag.p_promo_id
ORDER BY pd.p_promo_id
LIMIT 100
