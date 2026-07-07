WITH total_logs AS (
  SELECT wl_customer_id, COUNT(*) AS total_logs
  FROM web_logs
  GROUP BY wl_customer_id
),
customer_page_counts AS (
  SELECT wl_customer_id, wl_webpage_name, COUNT(*) AS page_view_cnt
  FROM web_logs
  GROUP BY wl_customer_id, wl_webpage_name
),
customer_top_page AS (
  SELECT wl_customer_id,
         wl_webpage_name,
         page_view_cnt,
         ROW_NUMBER() OVER (PARTITION BY wl_customer_id ORDER BY page_view_cnt DESC) AS rn
  FROM customer_page_counts
)
SELECT tp.wl_customer_id,
       tp.wl_webpage_name,
       tp.page_view_cnt,
       tl.total_logs
FROM customer_top_page tp
JOIN total_logs tl
  ON tp.wl_customer_id = tl.wl_customer_id
WHERE tp.rn = 1
ORDER BY tp.page_view_cnt DESC
LIMIT 10
