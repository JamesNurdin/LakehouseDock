WITH sales AS (
    SELECT c.c_customer_id,
           c.c_name,
           ss.ss_quantity AS quantity,
           i.i_price AS price,
           (SELECT AVG(pr.pr_rating)
            FROM product_reviews pr
            WHERE pr.pr_item_id = i.i_item_id) AS avg_rating
    FROM store_sales ss
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN items i ON ss.ss_item_id = i.i_item_id

    UNION ALL

    SELECT c.c_customer_id,
           c.c_name,
           ws.ws_quantity AS quantity,
           i.i_price AS price,
           (SELECT AVG(pr.pr_rating)
            FROM product_reviews pr
            WHERE pr.pr_item_id = i.i_item_id) AS avg_rating
    FROM web_sales ws
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    JOIN items i ON ws.ws_item_id = i.i_item_id
)
SELECT c_name,
       SUM(quantity) AS total_quantity,
       SUM(quantity * price) AS total_revenue,
       SUM(quantity * avg_rating) / NULLIF(SUM(quantity), 0) AS weighted_avg_rating
FROM sales
GROUP BY c_name
ORDER BY total_revenue DESC
LIMIT 10
