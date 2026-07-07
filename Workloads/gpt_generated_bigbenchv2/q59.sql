WITH sales_agg AS (
    SELECT i.i_category,
           i.i_category_id,
           SUM(u.quantity) AS total_quantity
    FROM (
        SELECT ss_item_id AS item_id, ss_quantity AS quantity FROM store_sales
        UNION ALL
        SELECT ws_item_id AS item_id, ws_quantity AS quantity FROM web_sales
    ) u
    JOIN items i ON u.item_id = i.i_item_id
    GROUP BY i.i_category, i.i_category_id
),
review_agg AS (
    SELECT i.i_category,
           i.i_category_id,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category, i.i_category_id
)
SELECT s.i_category,
       s.i_category_id,
       s.total_quantity,
       r.avg_sentiment,
       r.review_count
FROM sales_agg s
LEFT JOIN review_agg r
    ON s.i_category = r.i_category
   AND s.i_category_id = r.i_category_id
ORDER BY s.total_quantity DESC
LIMIT 10
