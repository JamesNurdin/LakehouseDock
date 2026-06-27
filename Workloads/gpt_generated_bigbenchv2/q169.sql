WITH sales AS (
        SELECT ss_item_id AS item_id,
               ss_quantity AS quantity,
               ss_customer_id AS customer_id,
               'store' AS channel
        FROM store_sales
        UNION ALL
        SELECT ws_item_id AS item_id,
               ws_quantity AS quantity,
               ws_customer_id AS customer_id,
               'web' AS channel
        FROM web_sales
    ),
    item_sales AS (
        SELECT i.i_item_id AS i_item_id,
               i.i_name,
               i.i_category_id,
               i.i_category_name,
               i.i_price,
               SUM(s.quantity) AS total_quantity,
               SUM(s.quantity) * i.i_price AS total_revenue,
               COUNT(DISTINCT s.customer_id) AS distinct_customers,
               COUNT(*) FILTER (WHERE s.channel = 'store') AS store_sales_count,
               COUNT(*) FILTER (WHERE s.channel = 'web') AS web_sales_count
        FROM items i
        LEFT JOIN sales s ON s.item_id = i.i_item_id
        GROUP BY i.i_item_id, i.i_name, i.i_category_id, i.i_category_name, i.i_price
    ),
    review_stats AS (
        SELECT pr.pr_item_id AS item_id,
               COUNT(*) AS review_count,
               AVG(pr.pr_rating) AS avg_rating,
               MAX(pr.pr_rating) AS max_rating,
               MIN(pr.pr_rating) AS min_rating
        FROM product_reviews pr
        GROUP BY pr.pr_item_id
    )
SELECT i.i_item_id,
       i.i_name,
       i.i_category_name,
       i.i_price,
       COALESCE(s.total_quantity, 0) AS total_quantity_sold,
       COALESCE(s.total_revenue, 0) AS total_revenue,
       COALESCE(r.review_count, 0) AS review_count,
       ROUND(COALESCE(r.avg_rating, 0), 2) AS avg_rating,
       s.store_sales_count,
       s.web_sales_count,
       s.distinct_customers
FROM items i
LEFT JOIN item_sales s ON s.i_item_id = i.i_item_id
LEFT JOIN review_stats r ON r.item_id = i.i_item_id
ORDER BY total_revenue DESC
LIMIT 20
