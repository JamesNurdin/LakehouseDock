WITH store_sales_agg AS (
    SELECT ss_item_id,
           SUM(ss_quantity) AS store_qty,
           SUM(ss_quantity * i_price) AS store_revenue
    FROM store_sales
    JOIN items ON store_sales.ss_item_id = items.i_item_id
    GROUP BY ss_item_id
),
web_sales_agg AS (
    SELECT ws_item_id,
           SUM(ws_quantity) AS web_qty,
           SUM(ws_quantity * i_price) AS web_revenue
    FROM web_sales
    JOIN items ON web_sales.ws_item_id = items.i_item_id
    GROUP BY ws_item_id
),
reviews_agg AS (
    SELECT pr_item_id,
           COUNT(*) AS review_count,
           AVG(pr_sentiment) AS avg_sentiment
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT i.i_category AS category,
       SUM(COALESCE(sa.store_qty, 0) + COALESCE(wa.web_qty, 0)) AS total_quantity,
       SUM(COALESCE(sa.store_revenue, 0) + COALESCE(wa.web_revenue, 0)) AS total_revenue,
       SUM(r.avg_sentiment * r.review_count) / NULLIF(SUM(r.review_count), 0) AS weighted_avg_sentiment,
       SUM(r.review_count) AS total_reviews
FROM items i
LEFT JOIN store_sales_agg sa ON i.i_item_id = sa.ss_item_id
LEFT JOIN web_sales_agg wa ON i.i_item_id = wa.ws_item_id
LEFT JOIN reviews_agg r ON i.i_item_id = r.pr_item_id
GROUP BY i.i_category
ORDER BY total_revenue DESC
LIMIT 10
