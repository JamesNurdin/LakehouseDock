WITH
store_sales_agg AS (
    SELECT i.i_item_id,
           i.i_category_id,
           i.i_category_name,
           i.i_price,
           SUM(ss.ss_quantity) AS total_store_qty,
           COUNT(DISTINCT ss.ss_customer_id) AS distinct_store_customers
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_item_id, i.i_category_id, i.i_category_name, i.i_price
),
web_sales_agg AS (
    SELECT i.i_item_id,
           i.i_category_id,
           i.i_category_name,
           i.i_price,
           SUM(ws.ws_quantity) AS total_web_qty,
           COUNT(DISTINCT ws.ws_customer_id) AS distinct_web_customers
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_item_id, i.i_category_id, i.i_category_name, i.i_price
),
reviews_agg AS (
    SELECT i.i_item_id,
           i.i_category_id,
           i.i_category_name,
           AVG(pr.pr_rating) AS avg_rating,
           COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id, i.i_category_id, i.i_category_name
),
distinct_customers_agg AS (
    SELECT i_item_id,
           COUNT(DISTINCT customer_id) AS distinct_customers
    FROM (
        SELECT ss.ss_item_id AS i_item_id, ss.ss_customer_id AS customer_id
        FROM store_sales ss
        UNION ALL
        SELECT ws.ws_item_id AS i_item_id, ws.ws_customer_id AS customer_id
        FROM web_sales ws
    ) combined
    GROUP BY i_item_id
)
SELECT i.i_item_id,
       i.i_category_name,
       i.i_price,
       COALESCE(s.total_store_qty, 0) AS total_store_qty,
       COALESCE(w.total_web_qty, 0) AS total_web_qty,
       COALESCE(s.total_store_qty, 0) + COALESCE(w.total_web_qty, 0) AS total_quantity,
       r.avg_rating,
       r.review_count,
       COALESCE(c.distinct_customers, 0) AS distinct_customers
FROM items i
LEFT JOIN store_sales_agg s ON i.i_item_id = s.i_item_id
LEFT JOIN web_sales_agg w ON i.i_item_id = w.i_item_id
LEFT JOIN reviews_agg r ON i.i_item_id = r.i_item_id
LEFT JOIN distinct_customers_agg c ON i.i_item_id = c.i_item_id
ORDER BY total_quantity DESC
LIMIT 100
