WITH sales_union AS (
    SELECT ss_item_id AS item_id,
           ss_quantity AS quantity,
           ss_customer_id AS customer_id,
           i_price AS price,
           i_category,
           i_category_id
    FROM store_sales
    JOIN items ON store_sales.ss_item_id = items.i_item_id

    UNION ALL

    SELECT ws_item_id AS item_id,
           ws_quantity AS quantity,
           ws_customer_id AS customer_id,
           i_price AS price,
           i_category,
           i_category_id
    FROM web_sales
    JOIN items ON web_sales.ws_item_id = items.i_item_id
),

sales_agg AS (
    SELECT i_category,
           i_category_id,
           SUM(quantity) AS total_quantity,
           SUM(quantity * price) AS total_revenue,
           COUNT(DISTINCT customer_id) AS distinct_customers
    FROM sales_union
    GROUP BY i_category, i_category_id
),

review_agg AS (
    SELECT i.i_category,
           i.i_category_id,
           SUM(pr.pr_sentiment) AS total_sentiment,
           COUNT(pr.pr_review_id) AS total_reviews
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category, i.i_category_id
)
SELECT
    s.i_category,
    s.i_category_id,
    s.total_quantity,
    s.total_revenue,
    s.distinct_customers,
    CASE WHEN r.total_reviews > 0 THEN r.total_sentiment / r.total_reviews ELSE NULL END AS avg_sentiment,
    r.total_reviews AS total_review_count
FROM sales_agg s
LEFT JOIN review_agg r
  ON r.i_category = s.i_category
 AND r.i_category_id = s.i_category_id
ORDER BY s.total_revenue DESC
LIMIT 10
