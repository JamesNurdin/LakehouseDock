WITH page_counts AS (
       SELECT
           wl_customer_id,
           wl_webpage_name,
           COUNT(*) AS page_views
       FROM web_logs
       GROUP BY wl_customer_id, wl_webpage_name
   ),
   max_page_counts AS (
       SELECT
           wl_customer_id,
           MAX(page_views) AS max_views
       FROM page_counts
       GROUP BY wl_customer_id
   ),
   top_page AS (
       SELECT
           pc.wl_customer_id,
           pc.wl_webpage_name AS top_webpage,
           pc.page_views AS top_page_views
       FROM page_counts pc
       JOIN max_page_counts mpc
         ON pc.wl_customer_id = mpc.wl_customer_id
        AND pc.page_views = mpc.max_views
   ),
   cust_agg AS (
       SELECT
           wl_customer_id,
           COUNT(*) AS total_views,
           COUNT(DISTINCT wl_item_id) AS distinct_items,
           MIN(wl_timestamp) AS first_visit,
           MAX(wl_timestamp) AS last_visit
       FROM web_logs
       GROUP BY wl_customer_id
   )
SELECT
    cust_agg.wl_customer_id,
    cust_agg.total_views,
    cust_agg.distinct_items,
    cust_agg.first_visit,
    cust_agg.last_visit,
    top_page.top_webpage,
    top_page.top_page_views
FROM cust_agg
JOIN top_page
  ON cust_agg.wl_customer_id = top_page.wl_customer_id
ORDER BY cust_agg.total_views DESC
LIMIT 100
