WITH store_sales_joined AS (
    SELECT ss.ss_item_id AS i_item_id,
           ss.ss_quantity AS quantity,
           i.i_category AS category
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
),
web_sales_joined AS (
    SELECT ws.ws_item_id AS i_item_id,
           ws.ws_quantity AS quantity,
           i.i_category AS category
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
),
sales_agg AS (
    SELECT i_item_id,
           category,
           SUM(quantity) AS total_quantity
    FROM (
        SELECT i_item_id, quantity, category FROM store_sales_joined
        UNION ALL
        SELECT i_item_id, quantity, category FROM web_sales_joined
    ) AS combined_sales
    GROUP BY i_item_id, category
),
reviews_agg AS (
    SELECT i.i_item_id,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
item_metrics AS (
    SELECT
        sa.category,
        sa.total_quantity,
        COALESCE(ra.avg_sentiment, 0) AS avg_sentiment,
        COALESCE(ra.review_count, 0) AS review_count
    FROM sales_agg sa
    LEFT JOIN reviews_agg ra ON sa.i_item_id = ra.i_item_id
)
SELECT
    im.category,
    SUM(im.total_quantity) AS total_quantity_sold,
    AVG(im.avg_sentiment) AS avg_sentiment,
    SUM(im.review_count) AS total_reviews
FROM item_metrics im
GROUP BY im.category
ORDER BY total_quantity_sold DESC
LIMIT 10
