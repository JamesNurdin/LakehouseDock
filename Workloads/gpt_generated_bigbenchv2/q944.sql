WITH store_agg AS (
    SELECT i.i_category_id,
           i.i_category,
           SUM(ss.ss_quantity) AS store_quantity,
           COUNT(DISTINCT ss.ss_customer_id) AS store_customers
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
web_agg AS (
    SELECT i.i_category_id,
           i.i_category,
           SUM(ws.ws_quantity) AS web_quantity,
           COUNT(DISTINCT ws.ws_customer_id) AS web_customers
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
review_agg AS (
    SELECT i.i_category_id,
           i.i_category,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
categories AS (
    SELECT DISTINCT i_category_id,
                    i_category
    FROM items
)
SELECT c.i_category_id,
       c.i_category,
       COALESCE(sa.store_quantity, 0) AS total_store_quantity,
       COALESCE(sa.store_customers, 0) AS total_store_customers,
       COALESCE(wa.web_quantity, 0) AS total_web_quantity,
       COALESCE(wa.web_customers, 0) AS total_web_customers,
       ra.avg_sentiment,
       ra.review_count
FROM categories c
LEFT JOIN store_agg sa ON c.i_category_id = sa.i_category_id AND c.i_category = sa.i_category
LEFT JOIN web_agg wa ON c.i_category_id = wa.i_category_id AND c.i_category = wa.i_category
LEFT JOIN review_agg ra ON c.i_category_id = ra.i_category_id AND c.i_category = ra.i_category
ORDER BY total_store_quantity DESC, total_web_quantity DESC
