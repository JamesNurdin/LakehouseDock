WITH sales_union AS (
    SELECT ss.ss_item_id AS item_id,
           ss.ss_quantity AS quantity,
           i.i_price AS price
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    UNION ALL
    SELECT ws.ws_item_id AS item_id,
           ws.ws_quantity AS quantity,
           i.i_price AS price
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
),
sales_agg AS (
    SELECT item_id,
           SUM(quantity) AS total_quantity,
           SUM(quantity * price) AS total_revenue
    FROM sales_union
    GROUP BY item_id
),
reviews_agg AS (
    SELECT pr.pr_item_id AS item_id,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT i.i_category_id,
       i.i_category,
       SUM(COALESCE(sa.total_quantity, 0)) AS total_quantity,
       SUM(COALESCE(sa.total_revenue, 0)) AS total_revenue,
       AVG(r.avg_sentiment) AS avg_sentiment,
       SUM(COALESCE(r.review_count, 0)) AS total_reviews
FROM items i
LEFT JOIN sales_agg sa ON sa.item_id = i.i_item_id
LEFT JOIN reviews_agg r ON r.item_id = i.i_item_id
GROUP BY i.i_category_id, i.i_category
ORDER BY total_revenue DESC
LIMIT 10
