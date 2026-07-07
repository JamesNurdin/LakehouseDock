WITH customer_summary AS (
    SELECT
        wl_customer_id,
        COUNT(*) AS total_page_views,
        COUNT(DISTINCT wl_item_id) AS distinct_items_viewed,
        MIN(CAST(wl_timestamp AS timestamp)) AS first_visit,
        MAX(CAST(wl_timestamp AS timestamp)) AS last_visit
    FROM web_logs
    GROUP BY wl_customer_id
)
SELECT
    wl.wl_id,
    wl.wl_customer_id,
    wl.wl_item_id,
    wl.wl_webpage_name,
    CAST(wl.wl_timestamp AS timestamp) AS view_timestamp,
    cs.total_page_views,
    cs.distinct_items_viewed,
    cs.first_visit,
    cs.last_visit
FROM web_logs wl
JOIN customer_summary cs
    ON wl.wl_customer_id = cs.wl_customer_id
WHERE cs.total_page_views > 100
ORDER BY cs.total_page_views DESC
LIMIT 100
