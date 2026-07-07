WITH store_agg AS (
    SELECT i.i_category_id,
           i.i_category,
           SUM(ss.ss_quantity) AS store_qty,
           SUM(ss.ss_quantity * i.i_price) AS store_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    GROUP BY i.i_category_id, i.i_category
),
web_agg AS (
    SELECT i.i_category_id,
           i.i_category,
           SUM(ws.ws_quantity) AS web_qty,
           SUM(ws.ws_quantity * i.i_price) AS web_revenue
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    GROUP BY i.i_category_id, i.i_category
),
review_agg AS (
    SELECT i.i_category_id,
           i.i_category,
           COUNT(pr.pr_review_id) AS review_count,
           AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
)
SELECT COALESCE(sa.i_category_id, wa.i_category_id, ra.i_category_id) AS category_id,
       COALESCE(sa.i_category, wa.i_category, ra.i_category) AS category,
       COALESCE(sa.store_qty, 0) + COALESCE(wa.web_qty, 0) AS total_quantity,
       COALESCE(sa.store_revenue, 0) + COALESCE(wa.web_revenue, 0) AS total_revenue,
       COALESCE(ra.review_count, 0) AS review_count,
       ra.avg_sentiment
FROM store_agg sa
FULL OUTER JOIN web_agg wa ON sa.i_category_id = wa.i_category_id
FULL OUTER JOIN review_agg ra ON COALESCE(sa.i_category_id, wa.i_category_id) = ra.i_category_id
ORDER BY total_revenue DESC
LIMIT 10
