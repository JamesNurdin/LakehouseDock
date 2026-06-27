WITH store_category_agg AS (
    SELECT i.i_category_id,
           i.i_category_name,
           SUM(ss.ss_quantity) AS store_qty,
           SUM(ss.ss_quantity * i.i_price) AS store_rev
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
web_category_agg AS (
    SELECT i.i_category_id,
           i.i_category_name,
           SUM(ws.ws_quantity) AS web_qty,
           SUM(ws.ws_quantity * i.i_price) AS web_rev
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
rating_agg AS (
    SELECT i.i_category_id,
           i.i_category_name,
           AVG(pr.pr_rating) AS avg_rating,
           COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
)
SELECT COALESCE(sc.i_category_id, wc.i_category_id, rc.i_category_id) AS category_id,
       COALESCE(sc.i_category_name, wc.i_category_name, rc.i_category_name) AS category_name,
       COALESCE(sc.store_qty, 0) AS total_store_quantity,
       COALESCE(sc.store_rev, 0.0) AS total_store_revenue,
       COALESCE(wc.web_qty, 0) AS total_web_quantity,
       COALESCE(wc.web_rev, 0.0) AS total_web_revenue,
       COALESCE(rc.avg_rating, 0) AS average_rating,
       COALESCE(rc.review_count, 0) AS total_review_count
FROM store_category_agg sc
FULL OUTER JOIN web_category_agg wc
    ON sc.i_category_id = wc.i_category_id
FULL OUTER JOIN rating_agg rc
    ON COALESCE(sc.i_category_id, wc.i_category_id) = rc.i_category_id
ORDER BY total_store_revenue DESC
LIMIT 10
