WITH store_sales_agg AS (
    SELECT i.i_category_id,
           i.i_category,
           SUM(ss.ss_quantity) AS store_qty,
           SUM(ss.ss_quantity * i.i_price) AS store_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
web_sales_agg AS (
    SELECT i.i_category_id,
           i.i_category,
           SUM(ws.ws_quantity) AS web_qty,
           SUM(ws.ws_quantity * i.i_price) AS web_revenue
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
review_agg AS (
    SELECT i.i_category_id,
           i.i_category,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
)
SELECT COALESCE(r.i_category_id, s.i_category_id, w.i_category_id) AS category_id,
       COALESCE(r.i_category, s.i_category, w.i_category) AS category_name,
       r.avg_sentiment,
       r.review_count,
       s.store_qty,
       s.store_revenue,
       w.web_qty,
       w.web_revenue,
       COALESCE(s.store_qty, 0) + COALESCE(w.web_qty, 0) AS total_qty,
       COALESCE(s.store_revenue, 0) + COALESCE(w.web_revenue, 0) AS total_revenue
FROM review_agg r
FULL OUTER JOIN store_sales_agg s ON r.i_category_id = s.i_category_id
FULL OUTER JOIN web_sales_agg w ON COALESCE(r.i_category_id, s.i_category_id) = w.i_category_id
ORDER BY total_revenue DESC
LIMIT 10
