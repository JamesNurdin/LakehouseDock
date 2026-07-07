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
sales AS (
    SELECT COALESCE(s.item_id, w.item_id) AS item_id,
           COALESCE(s.store_quantity, 0) + COALESCE(w.web_quantity, 0) AS total_quantity
    FROM store_sales_agg s
    FULL OUTER JOIN web_sales_agg w
        ON s.item_id = w.item_id
),
item_info AS (
    SELECT i.i_item_id,
           i.i_name,
           i.i_category_id,
           i.i_category,
           i.i_price
    FROM items i
),
review_agg AS (
    SELECT pr_item_id AS item_id,
           SUM(pr_sentiment) AS sum_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT
    ii.i_category,
    ii.i_category_id,
    SUM(s.total_quantity) AS total_quantity_sold,
    AVG(ii.i_price) AS avg_price,
    SUM(r.sum_sentiment) / NULLIF(SUM(r.review_count), 0) AS avg_review_sentiment,
    SUM(r.review_count) AS total_reviews
FROM sales s
JOIN item_info ii
    ON s.item_id = ii.i_item_id
LEFT JOIN review_agg r
    ON ii.i_item_id = r.item_id
GROUP BY ii.i_category, ii.i_category_id
ORDER BY total_quantity_sold DESC
LIMIT 20
