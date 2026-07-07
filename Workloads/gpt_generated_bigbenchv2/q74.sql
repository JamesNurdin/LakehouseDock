WITH store_category AS (
    SELECT ss.ss_store_id AS store_id,
           i.i_category_id AS category_id,
           i.i_category AS category_name,
           SUM(ss.ss_quantity) AS total_store_quantity,
           COUNT(DISTINCT ss.ss_customer_id) AS distinct_customers
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_store_id, i.i_category_id, i.i_category
),
web_category AS (
    SELECT i.i_category_id AS category_id,
           SUM(ws.ws_quantity) AS total_web_quantity
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id
),
review_category AS (
    SELECT i.i_category_id AS category_id,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id
)
SELECT s.s_store_name,
       sc.category_id,
       sc.category_name,
       sc.total_store_quantity,
       sc.distinct_customers,
       COALESCE(wc.total_web_quantity, 0) AS total_web_quantity,
       COALESCE(rc.review_count, 0) AS review_count,
       rc.avg_sentiment
FROM store_category sc
JOIN stores s ON sc.store_id = s.s_store_id
LEFT JOIN web_category wc ON sc.category_id = wc.category_id
LEFT JOIN review_category rc ON sc.category_id = rc.category_id
ORDER BY s.s_store_name, sc.category_id
