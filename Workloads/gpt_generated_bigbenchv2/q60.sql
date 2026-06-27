WITH store_sales_agg AS (
    SELECT ss_item_id,
           SUM(ss_quantity) AS store_quantity
    FROM store_sales
    GROUP BY ss_item_id
),
web_sales_agg AS (
    SELECT ws_item_id,
           SUM(ws_quantity) AS web_quantity
    FROM web_sales
    GROUP BY ws_item_id
),
reviews_agg AS (
    SELECT pr_item_id,
           COUNT(*) AS review_count,
           AVG(pr_rating) AS avg_rating
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT
    i.i_category_id,
    i.i_category_name,
    COUNT(DISTINCT i.i_item_id) AS item_count,
    SUM(COALESCE(ss.store_quantity, 0) + COALESCE(ws.web_quantity, 0)) AS total_quantity_sold,
    AVG(i.i_price) AS avg_price,
    SUM(COALESCE(ss.store_quantity, 0) + COALESCE(ws.web_quantity, 0)) * AVG(i.i_price) AS revenue_estimate,
    SUM(COALESCE(r.review_count, 0)) AS total_reviews,
    AVG(r.avg_rating) AS avg_rating
FROM items i
LEFT JOIN store_sales_agg ss ON ss.ss_item_id = i.i_item_id
LEFT JOIN web_sales_agg ws ON ws.ws_item_id = i.i_item_id
LEFT JOIN reviews_agg r ON r.pr_item_id = i.i_item_id
GROUP BY i.i_category_id, i.i_category_name
ORDER BY SUM(COALESCE(ss.store_quantity, 0) + COALESCE(ws.web_quantity, 0)) DESC
LIMIT 10
