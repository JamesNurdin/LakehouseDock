WITH sales AS (
    SELECT ss_item_id AS item_id,
           ss_customer_id AS customer_id,
           ss_quantity AS quantity,
           'store' AS channel
    FROM store_sales
    UNION ALL
    SELECT ws_item_id AS item_id,
           ws_customer_id AS customer_id,
           ws_quantity AS quantity,
           'web' AS channel
    FROM web_sales
),
sales_agg AS (
    SELECT i.i_category_id,
           i.i_category,
           SUM(CASE WHEN s.channel = 'store' THEN s.quantity ELSE 0 END) AS total_store_quantity,
           SUM(CASE WHEN s.channel = 'web' THEN s.quantity ELSE 0 END) AS total_web_quantity,
           SUM(s.quantity * i.i_price) AS total_revenue,
           COUNT(DISTINCT s.customer_id) AS distinct_customer_count
    FROM sales s
    JOIN items i ON s.item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
reviews_agg AS (
    SELECT i.i_category_id,
           AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id
)
SELECT
    s.i_category_id,
    s.i_category,
    s.total_store_quantity,
    s.total_web_quantity,
    s.total_revenue,
    r.avg_sentiment,
    s.distinct_customer_count
FROM sales_agg s
LEFT JOIN reviews_agg r ON s.i_category_id = r.i_category_id
ORDER BY s.total_revenue DESC
LIMIT 10
