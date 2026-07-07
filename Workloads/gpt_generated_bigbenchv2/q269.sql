WITH categories AS (
    SELECT DISTINCT i_category_id, i_category
    FROM items
),
store_sales_agg AS (
    SELECT i.i_category_id,
           SUM(ss.ss_quantity) AS store_qty,
           SUM(ss.ss_quantity * i.i_price) AS store_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category_id
),
web_sales_agg AS (
    SELECT i.i_category_id,
           SUM(ws.ws_quantity) AS web_qty,
           SUM(ws.ws_quantity * i.i_price) AS web_revenue
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id
),
reviews_agg AS (
    SELECT i.i_category_id,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id
)
SELECT c.i_category_id,
       c.i_category,
       COALESCE(sa.store_qty, 0) + COALESCE(wa.web_qty, 0) AS total_quantity,
       COALESCE(sa.store_revenue, 0) + COALESCE(wa.web_revenue, 0) AS total_revenue,
       ra.avg_sentiment,
       ra.review_count
FROM categories c
LEFT JOIN store_sales_agg sa ON c.i_category_id = sa.i_category_id
LEFT JOIN web_sales_agg wa ON c.i_category_id = wa.i_category_id
LEFT JOIN reviews_agg ra ON c.i_category_id = ra.i_category_id
ORDER BY total_revenue DESC
LIMIT 10
