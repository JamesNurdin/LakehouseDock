WITH store_sales_agg AS (
    SELECT ss_item_id AS i_item_id,
           SUM(ss_quantity) AS store_quantity
    FROM store_sales
    GROUP BY ss_item_id
),
web_sales_agg AS (
    SELECT ws_item_id AS i_item_id,
           SUM(ws_quantity) AS web_quantity
    FROM web_sales
    GROUP BY ws_item_id
),
product_reviews_agg AS (
    SELECT pr_item_id AS i_item_id,
           AVG(pr_rating) AS avg_rating,
           COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
),
item_sales AS (
    SELECT
        i.i_item_id,
        i.i_name,
        i.i_category_name,
        i.i_price,
        COALESCE(ss.store_quantity, 0) AS store_quantity,
        COALESCE(ws.web_quantity, 0) AS web_quantity,
        pr.avg_rating,
        COALESCE(pr.review_count, 0) AS review_count
    FROM items i
    LEFT JOIN store_sales_agg ss ON i.i_item_id = ss.i_item_id
    LEFT JOIN web_sales_agg ws ON i.i_item_id = ws.i_item_id
    LEFT JOIN product_reviews_agg pr ON i.i_item_id = pr.i_item_id
)
SELECT
    i_item_id,
    i_name,
    i_category_name,
    i_price,
    store_quantity,
    web_quantity,
    (store_quantity + web_quantity) AS total_quantity,
    i_price * store_quantity AS store_revenue,
    i_price * web_quantity AS web_revenue,
    i_price * (store_quantity + web_quantity) AS total_revenue,
    avg_rating,
    review_count,
    rank() OVER (ORDER BY i_price * (store_quantity + web_quantity) DESC) AS revenue_rank
FROM item_sales
ORDER BY total_revenue DESC
LIMIT 10
