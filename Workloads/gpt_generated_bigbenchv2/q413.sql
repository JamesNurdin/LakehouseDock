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
review_agg AS (
    SELECT pr_item_id,
           AVG(pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT
    i.i_item_id,
    i.i_name,
    i.i_category,
    COALESCE(s.store_quantity, 0) AS store_quantity,
    COALESCE(w.web_quantity, 0) AS web_quantity,
    (COALESCE(s.store_quantity, 0) + COALESCE(w.web_quantity, 0)) AS total_quantity,
    r.avg_sentiment,
    r.review_count,
    i.i_price
FROM items i
LEFT JOIN store_sales_agg s ON s.ss_item_id = i.i_item_id
LEFT JOIN web_sales_agg w ON w.ws_item_id = i.i_item_id
LEFT JOIN review_agg r ON r.pr_item_id = i.i_item_id
ORDER BY total_quantity DESC
LIMIT 10
