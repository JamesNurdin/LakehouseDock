WITH categories AS (
    SELECT DISTINCT i.i_category
    FROM items i
),
store_sales_agg AS (
    SELECT i.i_category,
           SUM(ss.ss_quantity) AS total_store_quantity,
           COUNT(DISTINCT ss.ss_customer_id) AS distinct_store_customers
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category
),
web_sales_agg AS (
    SELECT i.i_category,
           SUM(ws.ws_quantity) AS total_web_quantity,
           COUNT(DISTINCT ws.ws_customer_id) AS distinct_web_customers
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category
),
reviews_agg AS (
    SELECT i.i_category,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category
)
SELECT c.i_category,
       COALESCE(s.total_store_quantity, 0) AS total_store_quantity,
       COALESCE(s.distinct_store_customers, 0) AS distinct_store_customers,
       COALESCE(w.total_web_quantity, 0) AS total_web_quantity,
       COALESCE(w.distinct_web_customers, 0) AS distinct_web_customers,
       r.avg_sentiment,
       COALESCE(r.review_count, 0) AS review_count
FROM categories c
LEFT JOIN store_sales_agg s ON c.i_category = s.i_category
LEFT JOIN web_sales_agg w ON c.i_category = w.i_category
LEFT JOIN reviews_agg r ON c.i_category = r.i_category
ORDER BY c.i_category
