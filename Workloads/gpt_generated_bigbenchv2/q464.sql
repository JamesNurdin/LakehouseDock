WITH store_sales_agg AS (
    SELECT ss_item_id AS i_item_id,
           SUM(ss_quantity) AS store_qty
    FROM store_sales
    GROUP BY ss_item_id
),
web_sales_agg AS (
    SELECT ws_item_id AS i_item_id,
           SUM(ws_quantity) AS web_qty
    FROM web_sales
    GROUP BY ws_item_id
),
review_sentiment_agg AS (
    SELECT pr_item_id AS i_item_id,
           AVG(pr_sentiment) AS avg_sentiment
    FROM product_reviews
    GROUP BY pr_item_id
),
item_sales AS (
    SELECT i.i_item_id,
           i.i_category,
           i.i_category_id,
           COALESCE(s.store_qty, 0) + COALESCE(w.web_qty, 0) AS total_qty
    FROM items i
    LEFT JOIN store_sales_agg s ON i.i_item_id = s.i_item_id
    LEFT JOIN web_sales_agg w ON i.i_item_id = w.i_item_id
)
SELECT isales.i_category,
       isales.i_category_id,
       SUM(isales.total_qty) AS total_quantity_sold,
       AVG(r.avg_sentiment) AS avg_review_sentiment
FROM item_sales isales
LEFT JOIN review_sentiment_agg r ON isales.i_item_id = r.i_item_id
GROUP BY isales.i_category, isales.i_category_id
ORDER BY total_quantity_sold DESC
LIMIT 10
