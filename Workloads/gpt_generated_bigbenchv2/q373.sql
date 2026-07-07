WITH sales AS (
    SELECT i.i_category_id AS category_id,
           i.i_category AS category,
           i.i_price AS price,
           ss.ss_quantity AS quantity
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    UNION ALL
    SELECT i.i_category_id,
           i.i_category,
           i.i_price,
           ws.ws_quantity
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
),
sales_agg AS (
    SELECT category_id,
           category,
           SUM(quantity) AS total_quantity,
           SUM(price * quantity) AS total_revenue
    FROM sales
    GROUP BY category_id, category
),
reviews AS (
    SELECT i.i_category_id AS category_id,
           i.i_category AS category,
           COUNT(*) AS review_count,
           AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
)
SELECT s.category,
       s.total_quantity,
       s.total_revenue,
       COALESCE(r.review_count, 0) AS review_count,
       r.avg_sentiment
FROM sales_agg s
LEFT JOIN reviews r
    ON s.category_id = r.category_id
    AND s.category = r.category
ORDER BY s.total_revenue DESC
