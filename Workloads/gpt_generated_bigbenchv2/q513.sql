WITH store_sales_agg AS (
    SELECT ss_item_id AS i_item_id,
           SUM(ss_quantity) AS total_store_quantity
    FROM store_sales
    GROUP BY ss_item_id
),
web_sales_agg AS (
    SELECT ws_item_id AS i_item_id,
           SUM(ws_quantity) AS total_web_quantity
    FROM web_sales
    GROUP BY ws_item_id
),
reviews_agg AS (
    SELECT pr_item_id AS i_item_id,
           COUNT(*) AS review_count,
           AVG(pr_sentiment) AS avg_sentiment
    FROM product_reviews
    GROUP BY pr_item_id
),
item_sales AS (
    SELECT
        i.i_item_id,
        i.i_category_id,
        i.i_category,
        i.i_price,
        COALESCE(s.total_store_quantity, 0) AS store_qty,
        COALESCE(w.total_web_quantity, 0) AS web_qty,
        COALESCE(r.review_count, 0) AS review_cnt,
        r.avg_sentiment
    FROM items i
    LEFT JOIN store_sales_agg s ON s.i_item_id = i.i_item_id
    LEFT JOIN web_sales_agg w ON w.i_item_id = i.i_item_id
    LEFT JOIN reviews_agg r ON r.i_item_id = i.i_item_id
)
SELECT
    isales.i_category_id,
    isales.i_category,
    SUM(isales.store_qty) AS total_store_quantity,
    SUM(isales.web_qty) AS total_web_quantity,
    SUM(isales.store_qty + isales.web_qty) AS total_quantity,
    SUM((isales.store_qty + isales.web_qty) * isales.i_price) AS total_revenue,
    SUM(isales.review_cnt) AS total_review_count,
    AVG(isales.avg_sentiment) AS avg_sentiment
FROM item_sales isales
GROUP BY
    isales.i_category_id,
    isales.i_category
ORDER BY total_revenue DESC
LIMIT 10
