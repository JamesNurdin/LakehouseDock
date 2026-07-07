WITH item_info AS (
    SELECT i_item_id, i_category_id, i_category, i_price
    FROM items
),
review_stats AS (
    SELECT pr_item_id AS i_item_id, AVG(pr_sentiment) AS avg_sentiment
    FROM product_reviews
    GROUP BY pr_item_id
),
store_sales_stats AS (
    SELECT ss_item_id AS i_item_id,
           SUM(ss_quantity) AS store_quantity,
           SUM(ss_quantity * i_price) AS store_revenue
    FROM store_sales
    JOIN items ON store_sales.ss_item_id = items.i_item_id
    GROUP BY ss_item_id
),
web_sales_stats AS (
    SELECT ws_item_id AS i_item_id,
           SUM(ws_quantity) AS web_quantity,
           SUM(ws_quantity * i_price) AS web_revenue
    FROM web_sales
    JOIN items ON web_sales.ws_item_id = items.i_item_id
    GROUP BY ws_item_id
)
SELECT
    item_info.i_category_id,
    item_info.i_category,
    COALESCE(SUM(store_sales_stats.store_quantity), 0) + COALESCE(SUM(web_sales_stats.web_quantity), 0) AS total_quantity,
    COALESCE(SUM(store_sales_stats.store_revenue), 0) + COALESCE(SUM(web_sales_stats.web_revenue), 0) AS total_revenue,
    AVG(review_stats.avg_sentiment) AS avg_review_sentiment
FROM item_info
LEFT JOIN review_stats
    ON item_info.i_item_id = review_stats.i_item_id
LEFT JOIN store_sales_stats
    ON item_info.i_item_id = store_sales_stats.i_item_id
LEFT JOIN web_sales_stats
    ON item_info.i_item_id = web_sales_stats.i_item_id
GROUP BY item_info.i_category_id, item_info.i_category
ORDER BY total_revenue DESC
