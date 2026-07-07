WITH page_counts AS (
    SELECT wl_customer_id,
           wl_webpage_name,
           COUNT(*) AS page_view_count
    FROM web_logs
    GROUP BY wl_customer_id, wl_webpage_name
),
ranked_pages AS (
    SELECT wl_customer_id,
           wl_webpage_name,
           page_view_count,
           ROW_NUMBER() OVER (PARTITION BY wl_customer_id ORDER BY page_view_count DESC) AS rn
    FROM page_counts
),
top_pages AS (
    SELECT wl_customer_id,
           wl_webpage_name AS top_webpage,
           page_view_count AS top_page_views
    FROM ranked_pages
    WHERE rn = 1
),
total_views AS (
    SELECT wl_customer_id,
           COUNT(*) AS total_page_views
    FROM web_logs
    GROUP BY wl_customer_id
)
SELECT tv.wl_customer_id,
       tv.total_page_views,
       tp.top_webpage,
       tp.top_page_views
FROM total_views tv
JOIN top_pages tp
  ON tv.wl_customer_id = tp.wl_customer_id
ORDER BY tv.total_page_views DESC
LIMIT 10
