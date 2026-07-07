WITH all_sales AS (
    SELECT ss.ss_item_id AS i_item_id,
           ss.ss_quantity AS quantity,
           ss.ss_customer_id AS customer_id
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_item_id AS i_item_id,
           ws.ws_quantity AS quantity,
           ws.ws_customer_id AS customer_id
    FROM web_sales ws
),
sales_agg AS (
    SELECT i.i_item_id,
           i.i_category,
           SUM(s.quantity) AS total_quantity,
           COUNT(DISTINCT s.customer_id) AS distinct_customer_cnt
    FROM all_sales s
    INNER JOIN items i ON s.i_item_id = i.i_item_id
    GROUP BY i.i_item_id, i.i_category
),
reviews_agg AS (
    SELECT i.i_item_id,
           i.i_category,
           AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    INNER JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id, i.i_category
)
SELECT
    t.i_category,
    SUM(COALESCE(t.total_quantity, 0)) AS total_quantity_sold,
    SUM(COALESCE(t.total_quantity, 0) * t.i_price) AS total_revenue,
    AVG(t.avg_sentiment) AS avg_sentiment,
    SUM(COALESCE(t.distinct_customer_cnt, 0)) AS total_distinct_customers,
    COUNT(t.i_item_id) AS distinct_items_sold
FROM (
    SELECT i.i_item_id,
           i.i_category,
           i.i_price,
           sa.total_quantity,
           sa.distinct_customer_cnt,
           r.avg_sentiment
    FROM items i
    LEFT JOIN sales_agg sa ON i.i_item_id = sa.i_item_id
    LEFT JOIN reviews_agg r ON i.i_item_id = r.i_item_id
) t
GROUP BY t.i_category
ORDER BY total_quantity_sold DESC
