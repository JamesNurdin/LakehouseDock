WITH store_qty AS (
    SELECT ss_item_id AS item_id,
           SUM(ss_quantity) AS store_qty
    FROM store_sales
    GROUP BY ss_item_id
),
web_qty AS (
    SELECT ws_item_id AS item_id,
           SUM(ws_quantity) AS web_qty
    FROM web_sales
    GROUP BY ws_item_id
),
item_sales AS (
    SELECT COALESCE(s.item_id, w.item_id) AS item_id,
           COALESCE(s.store_qty, 0) AS store_qty,
           COALESCE(w.web_qty, 0) AS web_qty,
           COALESCE(s.store_qty, 0) + COALESCE(w.web_qty, 0) AS total_qty
    FROM store_qty s
    FULL OUTER JOIN web_qty w
        ON s.item_id = w.item_id
),
item_sentiment AS (
    SELECT pr_item_id AS item_id,
           SUM(pr_sentiment) AS sum_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
),
item_aggregated AS (
    SELECT i.i_item_id AS item_id,
           i.i_category AS category,
           i.i_name AS item_name,
           COALESCE(s.total_qty, 0) AS total_qty,
           COALESCE(r.sum_sentiment, 0) AS sum_sentiment,
           COALESCE(r.review_count, 0) AS review_count
    FROM items i
    LEFT JOIN item_sales s
        ON i.i_item_id = s.item_id
    LEFT JOIN item_sentiment r
        ON i.i_item_id = r.item_id
)
SELECT
    ia.category,
    SUM(ia.total_qty) AS total_quantity_sold,
    SUM(ia.sum_sentiment) AS total_sentiment,
    SUM(ia.review_count) AS total_reviews,
    CASE
        WHEN SUM(ia.review_count) > 0 THEN CAST(SUM(ia.sum_sentiment) AS double) / SUM(ia.review_count)
        ELSE NULL
    END AS avg_sentiment
FROM item_aggregated ia
GROUP BY ia.category
ORDER BY total_quantity_sold DESC
LIMIT 10
