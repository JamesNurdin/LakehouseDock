WITH sales AS (
    SELECT i.i_category_id,
           i.i_category,
           ss.ss_quantity AS quantity
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    UNION ALL
    SELECT i.i_category_id,
           i.i_category,
           ws.ws_quantity AS quantity
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
),

sales_agg AS (
    SELECT i_category_id,
           i_category,
           SUM(quantity) AS total_quantity_sold
    FROM sales
    GROUP BY i_category_id, i_category
),

reviews AS (
    SELECT i.i_category_id,
           i.i_category,
           pr.pr_sentiment AS sentiment
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
),

reviews_agg AS (
    SELECT i_category_id,
           i_category,
           AVG(sentiment) AS avg_sentiment
    FROM reviews
    GROUP BY i_category_id, i_category
)
SELECT s.i_category_id,
       s.i_category,
       s.total_quantity_sold,
       r.avg_sentiment
FROM sales_agg s
LEFT JOIN reviews_agg r ON s.i_category_id = r.i_category_id
ORDER BY s.total_quantity_sold DESC
