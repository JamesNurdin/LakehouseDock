WITH item_reviews AS (
    SELECT i.i_category_id,
           i.i_category,
           pr.pr_sentiment
    FROM product_reviews pr
    JOIN items i
      ON pr.pr_item_id = i.i_item_id
),
store_sales_summary AS (
    SELECT i.i_category_id,
           i.i_category,
           SUM(ss.ss_quantity) AS store_quantity
    FROM store_sales ss
    JOIN items i
      ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
web_sales_summary AS (
    SELECT i.i_category_id,
           i.i_category,
           SUM(ws.ws_quantity) AS web_quantity
    FROM web_sales ws
    JOIN items i
      ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
)
SELECT
    COALESCE(ss.i_category_id, ws.i_category_id, ir.i_category_id) AS category_id,
    COALESCE(ss.i_category, ws.i_category, ir.i_category) AS category_name,
    COALESCE(ss.store_quantity, 0) AS total_store_quantity,
    COALESCE(ws.web_quantity, 0) AS total_web_quantity,
    COALESCE(ss.store_quantity, 0) + COALESCE(ws.web_quantity, 0) AS total_quantity,
    AVG(ir.pr_sentiment) AS avg_review_sentiment
FROM store_sales_summary ss
FULL OUTER JOIN web_sales_summary ws
    ON ss.i_category_id = ws.i_category_id
FULL OUTER JOIN item_reviews ir
    ON COALESCE(ss.i_category_id, ws.i_category_id) = ir.i_category_id
GROUP BY
    COALESCE(ss.i_category_id, ws.i_category_id, ir.i_category_id),
    COALESCE(ss.i_category, ws.i_category, ir.i_category),
    COALESCE(ss.store_quantity, 0),
    COALESCE(ws.web_quantity, 0)
ORDER BY total_quantity DESC
