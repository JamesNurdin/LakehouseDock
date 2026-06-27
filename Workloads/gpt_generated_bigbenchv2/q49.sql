WITH review_stats AS (
    SELECT
        i.i_item_id,
        i.i_category_id,
        i.i_category_name,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(pr.pr_review_id) AS review_count
    FROM items i
    JOIN product_reviews pr ON pr.pr_item_id = i.i_item_id
    WHERE i.i_price > 5
      AND pr.pr_rating >= 3
    GROUP BY i.i_item_id, i.i_category_id, i.i_category_name
),
sales_stats AS (
    SELECT
        i.i_item_id,
        i.i_category_id,
        i.i_category_name,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(i.i_price * ss.ss_quantity) AS total_revenue,
        COUNT(ss.ss_transaction_id) AS transaction_count
    FROM items i
    JOIN store_sales ss ON ss.ss_item_id = i.i_item_id
    WHERE i.i_price > 5
    GROUP BY i.i_item_id, i.i_category_id, i.i_category_name
)
SELECT
    r.i_category_id,
    r.i_category_name,
    COUNT(DISTINCT r.i_item_id) AS item_count,
    AVG(r.avg_rating) AS category_avg_rating,
    SUM(r.review_count) AS total_reviews,
    SUM(s.total_quantity) AS category_total_quantity,
    SUM(s.total_revenue) AS category_total_revenue,
    CASE
        WHEN SUM(s.total_quantity) > 0 THEN SUM(s.total_revenue) / SUM(s.total_quantity)
        ELSE NULL
    END AS weighted_avg_price,
    SUM(s.transaction_count) AS total_transactions
FROM review_stats r
JOIN sales_stats s ON s.i_item_id = r.i_item_id
GROUP BY r.i_category_id, r.i_category_name
ORDER BY category_total_revenue DESC
LIMIT 10
