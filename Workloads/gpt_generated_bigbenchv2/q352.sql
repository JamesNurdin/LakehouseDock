WITH review_agg AS (
    SELECT pr_item_id,
           AVG(pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
),
sales_agg AS (
    SELECT ss_item_id,
           SUM(ss_quantity) AS total_quantity_sold,
           COUNT(*) AS sales_transactions
    FROM store_sales
    GROUP BY ss_item_id
)
SELECT i.i_category_id,
       i.i_category,
       COUNT(DISTINCT i.i_item_id) AS num_items,
       COALESCE(SUM(s.total_quantity_sold), 0) AS total_quantity_sold,
       AVG(i.i_price) AS avg_price,
       AVG(r.avg_sentiment) AS avg_sentiment,
       SUM(r.review_count) AS total_reviews
FROM items i
LEFT JOIN review_agg r ON r.pr_item_id = i.i_item_id
LEFT JOIN sales_agg s ON s.ss_item_id = i.i_item_id
GROUP BY i.i_category_id, i.i_category
ORDER BY total_quantity_sold DESC
LIMIT 10
