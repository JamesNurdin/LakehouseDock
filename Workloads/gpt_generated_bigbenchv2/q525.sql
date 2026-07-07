WITH combined_sales AS (
    SELECT ss.ss_item_id AS item_id,
           ss.ss_quantity AS quantity,
           s.s_store_name AS store_name,
           'store' AS channel
    FROM store_sales ss
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    UNION ALL
    SELECT ws.ws_item_id AS item_id,
           ws.ws_quantity AS quantity,
           'Web' AS store_name,
           'web' AS channel
    FROM web_sales ws
),
sales_agg AS (
    SELECT cs.store_name,
           i.i_category,
           i.i_category_id,
           SUM(cs.quantity) AS total_quantity_sold,
           AVG(i.i_price) AS avg_item_price
    FROM combined_sales cs
    JOIN items i ON cs.item_id = i.i_item_id
    GROUP BY cs.store_name, i.i_category, i.i_category_id
),
reviews_agg AS (
    SELECT i.i_category,
           i.i_category_id,
           COUNT(pr.pr_review_id) AS review_count,
           AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category, i.i_category_id
)
SELECT s.store_name,
       s.i_category,
       s.i_category_id,
       s.total_quantity_sold,
       s.avg_item_price,
       COALESCE(r.review_count, 0) AS review_count,
       r.avg_sentiment
FROM sales_agg s
LEFT JOIN reviews_agg r ON s.i_category = r.i_category AND s.i_category_id = r.i_category_id
ORDER BY s.store_name, s.total_quantity_sold DESC
LIMIT 100
