WITH store_sales_agg AS (
    SELECT ss_store_id,
           ss_item_id,
           SUM(ss_quantity) AS total_quantity
    FROM store_sales
    GROUP BY ss_store_id, ss_item_id
),
review_stats AS (
    SELECT pr_item_id,
           AVG(pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT
    s.s_store_id,
    s.s_store_name,
    i.i_category_id,
    i.i_category,
    SUM(sa.total_quantity) AS total_quantity_sold,
    AVG(rs.avg_sentiment) AS avg_category_sentiment,
    SUM(rs.review_count) AS total_reviews
FROM store_sales_agg sa
JOIN items i ON i.i_item_id = sa.ss_item_id
JOIN stores s ON s.s_store_id = sa.ss_store_id
LEFT JOIN review_stats rs ON rs.pr_item_id = i.i_item_id
GROUP BY s.s_store_id, s.s_store_name, i.i_category_id, i.i_category
ORDER BY total_quantity_sold DESC
LIMIT 10
