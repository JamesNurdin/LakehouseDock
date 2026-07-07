WITH store_agg AS (
    SELECT ss_item_id,
           SUM(ss_quantity) AS total_store_quantity,
           COUNT(DISTINCT ss_customer_id) AS distinct_store_customers
    FROM store_sales
    GROUP BY ss_item_id
),
web_agg AS (
    SELECT ws_item_id,
           SUM(ws_quantity) AS total_web_quantity,
           COUNT(DISTINCT ws_customer_id) AS distinct_web_customers
    FROM web_sales
    GROUP BY ws_item_id
),
review_agg AS (
    SELECT pr_item_id,
           AVG(pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT i.i_item_id,
       i.i_name,
       i.i_category,
       COALESCE(s.total_store_quantity, 0) AS total_store_quantity,
       COALESCE(w.total_web_quantity, 0) AS total_web_quantity,
       COALESCE(s.total_store_quantity, 0) + COALESCE(w.total_web_quantity, 0) AS total_quantity,
       (COALESCE(s.total_store_quantity, 0) + COALESCE(w.total_web_quantity, 0)) * i.i_price AS total_revenue,
       COALESCE(r.avg_sentiment, NULL) AS avg_sentiment,
       COALESCE(r.review_count, 0) AS review_count,
       COALESCE(s.distinct_store_customers, 0) + COALESCE(w.distinct_web_customers, 0) AS distinct_customers
FROM items i
LEFT JOIN store_agg s ON i.i_item_id = s.ss_item_id
LEFT JOIN web_agg w ON i.i_item_id = w.ws_item_id
LEFT JOIN review_agg r ON i.i_item_id = r.pr_item_id
ORDER BY total_revenue DESC
LIMIT 10
