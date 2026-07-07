WITH total_counts AS (
    SELECT
        wl_customer_id,
        COUNT(*) AS total_logs,
        COUNT(DISTINCT wl_item_id) AS distinct_items,
        COUNT(DISTINCT wl_webpage_name) AS distinct_pages
    FROM web_logs
    GROUP BY wl_customer_id
),
page_counts AS (
    SELECT
        wl_customer_id,
        wl_webpage_name,
        COUNT(*) AS page_views
    FROM web_logs
    GROUP BY wl_customer_id, wl_webpage_name
),
most_frequent_page AS (
    SELECT
        wl_customer_id,
        wl_webpage_name AS most_frequent_page
    FROM (
        SELECT
            wl_customer_id,
            wl_webpage_name,
            page_views,
            ROW_NUMBER() OVER (PARTITION BY wl_customer_id ORDER BY page_views DESC) AS rn
        FROM page_counts
    ) t
    WHERE rn = 1
)
SELECT
    tc.wl_customer_id,
    tc.total_logs,
    tc.distinct_items,
    tc.distinct_pages,
    mf.most_frequent_page
FROM total_counts tc
JOIN most_frequent_page mf
    ON tc.wl_customer_id = mf.wl_customer_id
ORDER BY tc.total_logs DESC
LIMIT 10
