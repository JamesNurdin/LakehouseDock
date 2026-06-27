/*
  Top 10 items by combined store and web revenue, with sales quantities and review statistics.
  - Aggregates store sales and web sales per item.
  - Joins product reviews to compute review count and average rating.
  - Uses only the allowed tables and join relationships.
*/
WITH store_sales_agg AS (
    SELECT
        ss.ss_item_id,
        SUM(ss.ss_quantity) AS total_store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_store_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_item_id
),
web_sales_agg AS (
    SELECT
        ws.ws_item_id,
        SUM(ws.ws_quantity) AS total_web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS total_web_revenue
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY ws.ws_item_id
),
reviews_agg AS (
    SELECT
        pr.pr_item_id,
        COUNT(*) AS review_count,
        AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT
    i.i_item_id,
    i.i_name,
    i.i_category_name,
    COALESCE(ss.total_store_quantity, 0) AS total_store_quantity,
    COALESCE(ws.total_web_quantity, 0) AS total_web_quantity,
    COALESCE(ss.total_store_quantity, 0) + COALESCE(ws.total_web_quantity, 0) AS total_quantity,
    COALESCE(ss.total_store_revenue, 0) + COALESCE(ws.total_web_revenue, 0) AS total_revenue,
    COALESCE(r.review_count, 0) AS review_count,
    r.avg_rating
FROM items i
LEFT JOIN store_sales_agg ss ON ss.ss_item_id = i.i_item_id
LEFT JOIN web_sales_agg ws ON ws.ws_item_id = i.i_item_id
LEFT JOIN reviews_agg r ON r.pr_item_id = i.i_item_id
ORDER BY total_revenue DESC
LIMIT 10
