WITH unified_sales AS (
    SELECT i.i_category_name AS category_name,
           ss.ss_quantity AS quantity,
           i.i_price AS price
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    UNION ALL
    SELECT i.i_category_name AS category_name,
           ws.ws_quantity AS quantity,
           i.i_price AS price
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
),
sales_agg AS (
    SELECT category_name,
           SUM(quantity) AS total_quantity,
           SUM(quantity * price) AS total_revenue
    FROM unified_sales
    GROUP BY category_name
),
rating_agg AS (
    SELECT i.i_category_name AS category_name,
           AVG(pr.pr_rating) AS average_rating
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_name
)
SELECT s.category_name,
       s.total_quantity,
       s.total_revenue,
       r.average_rating
FROM sales_agg s
LEFT JOIN rating_agg r ON s.category_name = r.category_name
ORDER BY s.total_revenue DESC
