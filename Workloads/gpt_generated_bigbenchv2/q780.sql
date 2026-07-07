WITH sales_union AS (
    SELECT ss.ss_item_id AS item_id,
           ss.ss_quantity AS quantity,
           i.i_price AS price,
           ss.ss_customer_id AS customer_id
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    UNION ALL
    SELECT ws.ws_item_id AS item_id,
           ws.ws_quantity AS quantity,
           i.i_price AS price,
           ws.ws_customer_id AS customer_id
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
),
sales_agg AS (
    SELECT item_id,
           SUM(quantity) AS total_quantity,
           SUM(quantity * price) AS total_revenue,
           COUNT(DISTINCT customer_id) AS distinct_customers
    FROM sales_union
    GROUP BY item_id
),
review_agg AS (
    SELECT pr.pr_item_id AS item_id,
           SUM(pr.pr_sentiment) AS sum_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT i.i_category_id,
       i.i_category,
       SUM(s.total_quantity) AS total_quantity_sold,
       SUM(s.total_revenue) AS total_revenue,
       COUNT(DISTINCT s.item_id) AS distinct_items_sold,
       SUM(s.distinct_customers) AS total_distinct_customers,
       COALESCE(SUM(r.sum_sentiment) / NULLIF(SUM(r.review_count), 0), 0) AS avg_sentiment,
       SUM(COALESCE(r.review_count, 0)) AS total_review_count
FROM sales_agg s
JOIN items i ON s.item_id = i.i_item_id
LEFT JOIN review_agg r ON i.i_item_id = r.item_id
GROUP BY i.i_category_id, i.i_category
ORDER BY total_quantity_sold DESC
LIMIT 10
