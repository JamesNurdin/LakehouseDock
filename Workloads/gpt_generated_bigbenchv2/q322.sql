WITH store_agg AS (
    SELECT i.i_category_name AS category_name,
           SUM(ss.ss_quantity) AS store_quantity,
           SUM(ss.ss_quantity * i.i_price) AS store_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category_name
),
web_agg AS (
    SELECT i.i_category_name AS category_name,
           SUM(ws.ws_quantity) AS web_quantity,
           SUM(ws.ws_quantity * i.i_price) AS web_revenue
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_name
),
rating_agg AS (
    SELECT i.i_category_name AS category_name,
           AVG(pr.pr_rating) AS avg_rating,
           COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_name
)
SELECT COALESCE(s.category_name, w.category_name, r.category_name) AS category_name,
       COALESCE(s.store_quantity, 0) AS store_quantity,
       COALESCE(s.store_revenue, 0) AS store_revenue,
       COALESCE(w.web_quantity, 0) AS web_quantity,
       COALESCE(w.web_revenue, 0) AS web_revenue,
       COALESCE(r.avg_rating, 0) AS avg_rating,
       COALESCE(r.review_count, 0) AS review_count
FROM store_agg s
FULL OUTER JOIN web_agg w ON s.category_name = w.category_name
FULL OUTER JOIN rating_agg r ON COALESCE(s.category_name, w.category_name) = r.category_name
ORDER BY category_name
