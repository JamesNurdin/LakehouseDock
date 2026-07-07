WITH sales AS (
    SELECT ss.ss_customer_id AS customer_id,
           ss.ss_item_id AS item_id,
           ss.ss_quantity AS quantity,
           i.i_price AS price,
           i.i_category_id,
           i.i_category
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
),
web AS (
    SELECT ws.ws_customer_id AS customer_id,
           ws.ws_item_id AS item_id,
           ws.ws_quantity AS quantity,
           i.i_price AS price,
           i.i_category_id,
           i.i_category
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
),
all_sales AS (
    SELECT * FROM sales
    UNION ALL
    SELECT * FROM web
),
review_agg AS (
    SELECT pr.pr_item_id AS item_id,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT a.i_category_id,
       a.i_category,
       SUM(a.quantity) AS total_quantity_sold,
       SUM(a.quantity * a.price) AS total_revenue,
       AVG(r.avg_sentiment) AS avg_item_sentiment,
       SUM(r.review_count) AS total_reviews
FROM all_sales a
LEFT JOIN review_agg r ON a.item_id = r.item_id
GROUP BY a.i_category_id, a.i_category
ORDER BY total_revenue DESC
LIMIT 10
