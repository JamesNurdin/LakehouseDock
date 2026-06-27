WITH sales AS (
    SELECT i.i_category_id,
           i.i_category_name,
           SUM(ss.ss_quantity) AS store_quantity,
           SUM(ss.ss_quantity * i.i_price) AS store_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
web AS (
    SELECT i.i_category_id,
           i.i_category_name,
           SUM(ws.ws_quantity) AS web_quantity,
           SUM(ws.ws_quantity * i.i_price) AS web_revenue
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
sales_combined AS (
    SELECT COALESCE(s.i_category_id, w.i_category_id) AS i_category_id,
           COALESCE(s.i_category_name, w.i_category_name) AS i_category_name,
           COALESCE(s.store_quantity, 0) + COALESCE(w.web_quantity, 0) AS total_quantity,
           COALESCE(s.store_revenue, 0) + COALESCE(w.web_revenue, 0) AS total_revenue
    FROM sales s
    FULL OUTER JOIN web w
      ON s.i_category_id = w.i_category_id
),
review_agg AS (
    SELECT i.i_category_id,
           i.i_category_name,
           AVG(pr.pr_rating) AS avg_rating,
           COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
)
SELECT sc.i_category_id,
       sc.i_category_name,
       sc.total_quantity,
       sc.total_revenue,
       ra.avg_rating,
       ra.review_count
FROM sales_combined sc
LEFT JOIN review_agg ra
  ON sc.i_category_id = ra.i_category_id
ORDER BY sc.total_revenue DESC
LIMIT 10
