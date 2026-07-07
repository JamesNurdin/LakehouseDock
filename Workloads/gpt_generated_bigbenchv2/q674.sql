WITH all_sales AS (
    SELECT ss_item_id AS i_item_id, ss_quantity AS quantity FROM store_sales
    UNION ALL
    SELECT ws_item_id AS i_item_id, ws_quantity AS quantity FROM web_sales
),
sales_agg AS (
    SELECT i_item_id, SUM(quantity) AS total_quantity
    FROM all_sales
    GROUP BY i_item_id
),
review_agg AS (
    SELECT i.i_category,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category
),
final AS (
    SELECT i.i_category,
           ra.avg_sentiment,
           ra.review_count,
           SUM(COALESCE(sa.total_quantity, 0)) AS total_quantity_sold
    FROM items i
    LEFT JOIN sales_agg sa ON i.i_item_id = sa.i_item_id
    JOIN review_agg ra ON i.i_category = ra.i_category
    GROUP BY i.i_category, ra.avg_sentiment, ra.review_count
)
SELECT i_category,
       avg_sentiment,
       review_count,
       total_quantity_sold
FROM final
ORDER BY total_quantity_sold DESC
LIMIT 10
