WITH store_agg AS (
    SELECT ss_item_id AS i_item_id,
           SUM(ss_quantity) AS store_quantity,
           SUM(ss_quantity * i_price) AS store_revenue
    FROM store_sales
    JOIN items ON store_sales.ss_item_id = items.i_item_id
    GROUP BY ss_item_id
),
web_agg AS (
    SELECT ws_item_id AS i_item_id,
           SUM(ws_quantity) AS web_quantity,
           SUM(ws_quantity * i_price) AS web_revenue
    FROM web_sales
    JOIN items ON web_sales.ws_item_id = items.i_item_id
    GROUP BY ws_item_id
),
review_agg AS (
    SELECT pr_item_id AS i_item_id,
           COUNT(*) AS review_count,
           AVG(pr_rating) AS avg_rating
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT i.i_item_id,
       i.i_name,
       i.i_category_name,
       i.i_price,
       COALESCE(s.store_quantity, 0) AS store_quantity,
       COALESCE(w.web_quantity, 0) AS web_quantity,
       COALESCE(s.store_quantity, 0) + COALESCE(w.web_quantity, 0) AS total_quantity,
       COALESCE(s.store_revenue, 0) + COALESCE(w.web_revenue, 0) AS total_revenue,
       COALESCE(r.review_count, 0) AS review_count,
       r.avg_rating
FROM items i
LEFT JOIN store_agg s ON i.i_item_id = s.i_item_id
LEFT JOIN web_agg w ON i.i_item_id = w.i_item_id
LEFT JOIN review_agg r ON i.i_item_id = r.i_item_id
WHERE COALESCE(r.review_count, 0) >= 5
ORDER BY total_revenue DESC
LIMIT 10
