WITH store_sales_agg AS (
    SELECT i.i_category_id AS category_id,
           i.i_category AS category_name,
           SUM(ss.ss_quantity) AS store_quantity
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
web_sales_agg AS (
    SELECT i.i_category_id AS category_id,
           i.i_category AS category_name,
           SUM(ws.ws_quantity) AS web_quantity
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
reviews_agg AS (
    SELECT i.i_category_id AS category_id,
           i.i_category AS category_name,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
)
SELECT COALESCE(ss.category_id, ws.category_id, r.category_id) AS category_id,
       COALESCE(ss.category_name, ws.category_name, r.category_name) AS category_name,
       COALESCE(ss.store_quantity, 0) + COALESCE(ws.web_quantity, 0) AS total_quantity_sold,
       r.avg_sentiment,
       r.review_count
FROM store_sales_agg ss
FULL OUTER JOIN web_sales_agg ws
    ON ss.category_id = ws.category_id
FULL OUTER JOIN reviews_agg r
    ON COALESCE(ss.category_id, ws.category_id) = r.category_id
ORDER BY total_quantity_sold DESC
