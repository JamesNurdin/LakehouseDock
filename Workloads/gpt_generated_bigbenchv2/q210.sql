WITH store_sales_agg AS (
    SELECT i.i_category_id,
           i.i_category,
           SUM(ss.ss_quantity) AS total_store_quantity
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
web_sales_agg AS (
    SELECT i.i_category_id,
           i.i_category,
           SUM(ws.ws_quantity) AS total_web_quantity
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
reviews_agg AS (
    SELECT i.i_category_id,
           i.i_category,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
customers_per_category AS (
    SELECT i.i_category_id,
           i.i_category,
           c.c_customer_id
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    UNION DISTINCT
    SELECT i.i_category_id,
           i.i_category,
           c.c_customer_id
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
),
distinct_customers_agg AS (
    SELECT i_category_id,
           i_category,
           COUNT(DISTINCT c_customer_id) AS distinct_customer_count
    FROM customers_per_category
    GROUP BY i_category_id, i_category
)
SELECT s.i_category_id,
       s.i_category,
       s.total_store_quantity,
       w.total_web_quantity,
       r.avg_sentiment,
       r.review_count,
       d.distinct_customer_count
FROM store_sales_agg s
LEFT JOIN web_sales_agg w
    ON s.i_category_id = w.i_category_id
   AND s.i_category = w.i_category
LEFT JOIN reviews_agg r
    ON s.i_category_id = r.i_category_id
   AND s.i_category = r.i_category
LEFT JOIN distinct_customers_agg d
    ON s.i_category_id = d.i_category_id
   AND s.i_category = d.i_category
ORDER BY s.total_store_quantity DESC
LIMIT 10
