WITH sales_combined AS (
    SELECT ss.ss_item_id AS item_id,
           ss.ss_quantity AS quantity,
           ss.ss_customer_id AS customer_id
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_item_id AS item_id,
           ws.ws_quantity AS quantity,
           ws.ws_customer_id AS customer_id
    FROM web_sales ws
),

sales_agg AS (
    SELECT i.i_category_id,
           i.i_category,
           SUM(sc.quantity) AS total_quantity,
           COUNT(DISTINCT sc.customer_id) AS distinct_customer_count
    FROM sales_combined sc
    JOIN items i ON sc.item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),

review_agg AS (
    SELECT i.i_category_id,
           i.i_category,
           AVG(pr.pr_sentiment) AS avg_review_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
)
SELECT
    s.i_category_id AS category_id,
    s.i_category AS category_name,
    s.total_quantity,
    s.distinct_customer_count,
    COALESCE(r.avg_review_sentiment, 0) AS avg_review_sentiment,
    COALESCE(r.review_count, 0) AS review_count
FROM sales_agg s
LEFT JOIN review_agg r ON s.i_category_id = r.i_category_id
ORDER BY s.total_quantity DESC
LIMIT 20
