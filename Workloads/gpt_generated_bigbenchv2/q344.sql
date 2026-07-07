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
reviews_agg AS (
    SELECT pr_item_id AS item_id,
           COUNT(*) AS review_count,
           SUM(pr_sentiment) AS sentiment_sum
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT
    i.i_category AS category,
    SUM(COALESCE(ss.store_quantity, 0) + COALESCE(ws.web_quantity, 0)) AS total_quantity_sold,
    SUM(COALESCE(ss.store_quantity, 0)) AS total_store_quantity,
    SUM(COALESCE(ws.web_quantity, 0)) AS total_web_quantity,
    SUM(COALESCE(r.review_count, 0)) AS total_reviews,
    CASE
        WHEN SUM(COALESCE(r.review_count, 0)) > 0 THEN
            CAST(SUM(COALESCE(r.sentiment_sum, 0)) AS double) / SUM(COALESCE(r.review_count, 0))
        ELSE NULL
    END AS avg_sentiment,
    AVG(i.i_price) AS avg_price,
    AVG(i.i_comp_price) AS avg_comp_price
FROM items i
LEFT JOIN store_sales_agg ss ON ss.item_id = i.i_item_id
LEFT JOIN web_sales_agg ws ON ws.item_id = i.i_item_id
LEFT JOIN reviews_agg r ON r.item_id = i.i_item_id
GROUP BY i.i_category
ORDER BY total_quantity_sold DESC
