WITH store_sales_agg AS (
    SELECT ss_item_id AS item_id,
           SUM(ss_quantity) AS store_quantity
    FROM store_sales
    GROUP BY ss_item_id
),
web_sales_agg AS (
    SELECT ws_item_id AS item_id,
           SUM(ws_quantity) AS web_quantity
    FROM web_sales
    GROUP BY ws_item_id
),
sales_agg AS (
    SELECT i.i_item_id,
           i.i_name,
           i.i_category,
           i.i_price,
           COALESCE(s.store_quantity, 0) + COALESCE(w.web_quantity, 0) AS total_quantity
    FROM items i
    LEFT JOIN store_sales_agg s ON i.i_item_id = s.item_id
    LEFT JOIN web_sales_agg w ON i.i_item_id = w.item_id
),
review_agg AS (
    SELECT pr_item_id AS item_id,
           AVG(pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT s.i_item_id,
       s.i_name,
       s.i_category,
       s.i_price,
       s.total_quantity,
       (s.total_quantity * s.i_price) AS total_revenue,
       r.avg_sentiment,
       r.review_count
FROM sales_agg s
LEFT JOIN review_agg r ON s.i_item_id = r.item_id
ORDER BY total_revenue DESC
LIMIT 10
