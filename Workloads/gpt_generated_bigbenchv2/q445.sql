WITH store_sales_agg AS (
    SELECT i.i_item_id,
           SUM(ss.ss_quantity) AS store_qty,
           SUM(ss.ss_quantity * i.i_price) AS store_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
web_sales_agg AS (
    SELECT i.i_item_id,
           SUM(ws.ws_quantity) AS web_qty,
           SUM(ws.ws_quantity * i.i_price) AS web_revenue
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
reviews_agg AS (
    SELECT i.i_item_id,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
)
SELECT i.i_category,
       i.i_category_id,
       SUM(COALESCE(ssa.store_qty, 0) + COALESCE(wsa.web_qty, 0)) AS total_quantity,
       SUM(COALESCE(ssa.store_revenue, 0) + COALESCE(wsa.web_revenue, 0)) AS total_revenue,
       AVG(r.avg_sentiment) AS avg_sentiment,
       SUM(r.review_count) AS total_reviews
FROM items i
LEFT JOIN store_sales_agg ssa ON i.i_item_id = ssa.i_item_id
LEFT JOIN web_sales_agg wsa ON i.i_item_id = wsa.i_item_id
LEFT JOIN reviews_agg r ON i.i_item_id = r.i_item_id
GROUP BY i.i_category, i.i_category_id
ORDER BY total_revenue DESC
LIMIT 10
