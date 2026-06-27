WITH
    categories AS (
        SELECT DISTINCT i_category_id,
                        i_category_name
        FROM items
    ),
    store_agg AS (
        SELECT i.i_category_id,
               SUM(ss.ss_quantity) AS store_quantity,
               SUM(ss.ss_quantity * i.i_price) AS store_revenue,
               COUNT(DISTINCT ss.ss_customer_id) AS store_customers
        FROM store_sales ss
        JOIN items i ON ss.ss_item_id = i.i_item_id
        GROUP BY i.i_category_id
    ),
    web_agg AS (
        SELECT i.i_category_id,
               SUM(ws.ws_quantity) AS web_quantity,
               SUM(ws.ws_quantity * i.i_price) AS web_revenue,
               COUNT(DISTINCT ws.ws_customer_id) AS web_customers
        FROM web_sales ws
        JOIN items i ON ws.ws_item_id = i.i_item_id
        GROUP BY i.i_category_id
    ),
    review_agg AS (
        SELECT i.i_category_id,
               COUNT(pr.pr_review_id) AS review_count,
               AVG(pr.pr_rating) AS avg_rating
        FROM product_reviews pr
        JOIN items i ON pr.pr_item_id = i.i_item_id
        GROUP BY i.i_category_id
    )
SELECT c.i_category_id AS category_id,
       c.i_category_name AS category_name,
       COALESCE(sa.store_quantity, 0) AS total_store_quantity,
       COALESCE(wa.web_quantity, 0)   AS total_web_quantity,
       COALESCE(sa.store_revenue, 0)  AS total_store_revenue,
       COALESCE(wa.web_revenue, 0)    AS total_web_revenue,
       COALESCE(sa.store_customers, 0) + COALESCE(wa.web_customers, 0) AS total_customers,
       COALESCE(ra.review_count, 0)   AS total_reviews,
       COALESCE(ra.avg_rating, 0)     AS average_rating
FROM categories c
LEFT JOIN store_agg sa ON c.i_category_id = sa.i_category_id
LEFT JOIN web_agg wa   ON c.i_category_id = wa.i_category_id
LEFT JOIN review_agg ra ON c.i_category_id = ra.i_category_id
ORDER BY (COALESCE(sa.store_revenue, 0) + COALESCE(wa.web_revenue, 0)) DESC
LIMIT 10
