WITH items_cte AS (
    SELECT i_item_id,
           i_category_id,
           i_category_name,
           i_price
    FROM items
),
store_sales_agg AS (
    SELECT i.i_category_id,
           i.i_category_name,
           SUM(ss.ss_quantity) AS total_instore_quantity,
           COUNT(DISTINCT ss.ss_store_id) AS store_count
    FROM store_sales ss
    JOIN items_cte i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
web_sales_agg AS (
    SELECT i.i_category_id,
           i.i_category_name,
           SUM(ws.ws_quantity) AS total_web_quantity
    FROM web_sales ws
    JOIN items_cte i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
rating_agg AS (
    SELECT i.i_category_id,
           i.i_category_name,
           AVG(pr.pr_rating) AS avg_rating,
           COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items_cte i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
price_agg AS (
    SELECT i_category_id,
           i_category_name,
           AVG(i_price) AS avg_price
    FROM items_cte
    GROUP BY i_category_id, i_category_name
)
SELECT
    COALESCE(p.i_category_id, s.i_category_id, w.i_category_id, r.i_category_id) AS category_id,
    COALESCE(p.i_category_name, s.i_category_name, w.i_category_name, r.i_category_name) AS category_name,
    COALESCE(s.total_instore_quantity, 0) AS total_instore_quantity,
    COALESCE(w.total_web_quantity, 0) AS total_web_quantity,
    COALESCE(r.avg_rating, 0) AS avg_rating,
    COALESCE(r.review_count, 0) AS review_count,
    COALESCE(p.avg_price, 0) AS avg_price,
    COALESCE(s.store_count, 0) AS store_count
FROM price_agg p
FULL OUTER JOIN store_sales_agg s ON p.i_category_id = s.i_category_id
FULL OUTER JOIN web_sales_agg w ON p.i_category_id = w.i_category_id
FULL OUTER JOIN rating_agg r ON p.i_category_id = r.i_category_id
ORDER BY total_instore_quantity + total_web_quantity DESC
LIMIT 10
