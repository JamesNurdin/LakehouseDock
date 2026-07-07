WITH store_sales_agg AS (
    SELECT ss.ss_item_id AS item_id,
           SUM(ss.ss_quantity) AS store_quantity
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_item_id
),
web_sales_agg AS (
    SELECT ws.ws_item_id AS item_id,
           SUM(ws.ws_quantity) AS web_quantity
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY ws.ws_item_id
),
sales_agg AS (
    SELECT COALESCE(s.item_id, w.item_id) AS item_id,
           COALESCE(s.store_quantity, 0) + COALESCE(w.web_quantity, 0) AS total_quantity
    FROM store_sales_agg s
    FULL OUTER JOIN web_sales_agg w ON s.item_id = w.item_id
),
review_agg AS (
    SELECT pr.pr_item_id AS item_id,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT i.i_category,
       i.i_category_id,
       SUM(s.total_quantity) AS total_quantity_sold,
       AVG(r.avg_sentiment) AS avg_review_sentiment,
       COUNT(DISTINCT i.i_item_id) AS distinct_items_sold
FROM sales_agg s
JOIN items i ON s.item_id = i.i_item_id
LEFT JOIN review_agg r ON i.i_item_id = r.item_id
GROUP BY i.i_category, i.i_category_id
ORDER BY total_quantity_sold DESC
LIMIT 10
