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
sales_agg AS (
    SELECT COALESCE(s.item_id, w.item_id) AS item_id,
           COALESCE(s.store_quantity, 0) + COALESCE(w.web_quantity, 0) AS total_quantity
    FROM store_sales_agg s
    FULL OUTER JOIN web_sales_agg w
        ON s.item_id = w.item_id
),
review_agg AS (
    SELECT i.i_category AS category,
           AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category
),
sales_by_category AS (
    SELECT i.i_category AS category,
           SUM(sa.total_quantity) AS total_quantity
    FROM sales_agg sa
    JOIN items i ON sa.item_id = i.i_item_id
    GROUP BY i.i_category
)
SELECT sbc.category,
       sbc.total_quantity,
       ra.avg_sentiment
FROM sales_by_category sbc
LEFT JOIN review_agg ra
    ON sbc.category = ra.category
ORDER BY sbc.total_quantity DESC
