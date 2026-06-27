WITH unified_sales AS (
    SELECT ss_item_id AS i_item_id,
           ss_quantity AS quantity
    FROM store_sales
    UNION ALL
    SELECT ws_item_id AS i_item_id,
           ws_quantity AS quantity
    FROM web_sales
),

sales_agg AS (
    SELECT us.i_item_id,
           SUM(us.quantity) AS total_quantity,
           SUM(us.quantity * i.i_price) AS total_revenue
    FROM unified_sales us
    JOIN items i ON us.i_item_id = i.i_item_id
    GROUP BY us.i_item_id
),

reviews_agg AS (
    SELECT pr.pr_item_id AS i_item_id,
           COUNT(*) AS review_count,
           AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
),

customer_items AS (
    SELECT ss.ss_customer_id AS c_customer_id,
           ss.ss_item_id AS i_item_id
    FROM store_sales ss
    UNION
    SELECT ws.ws_customer_id AS c_customer_id,
           ws.ws_item_id AS i_item_id
    FROM web_sales ws
),

customer_agg AS (
    SELECT ci.i_item_id,
           COUNT(DISTINCT ci.c_customer_id) AS distinct_customers
    FROM customer_items ci
    GROUP BY ci.i_item_id
)
SELECT i.i_category_id,
       i.i_category_name,
       SUM(COALESCE(s.total_quantity, 0)) AS category_quantity,
       SUM(COALESCE(s.total_revenue, 0)) AS category_revenue,
       SUM(COALESCE(r.avg_rating * r.review_count, 0)) / NULLIF(SUM(COALESCE(r.review_count, 0)), 0) AS category_avg_rating,
       SUM(COALESCE(r.review_count, 0)) AS category_review_count,
       SUM(COALESCE(c.distinct_customers, 0)) AS category_distinct_customers
FROM items i
LEFT JOIN sales_agg s ON i.i_item_id = s.i_item_id
LEFT JOIN reviews_agg r ON i.i_item_id = r.i_item_id
LEFT JOIN customer_agg c ON i.i_item_id = c.i_item_id
GROUP BY i.i_category_id, i.i_category_name
ORDER BY category_revenue DESC
LIMIT 10
