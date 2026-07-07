WITH store_sales_agg AS (
    SELECT i.i_category_id,
           i.i_category,
           SUM(ss.ss_quantity) AS store_qty
    FROM store_sales ss
    INNER JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
web_sales_agg AS (
    SELECT i.i_category_id,
           i.i_category,
           SUM(ws.ws_quantity) AS web_qty
    FROM web_sales ws
    INNER JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
review_agg AS (
    SELECT i.i_category_id,
           i.i_category,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews pr
    INNER JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
)
SELECT COALESCE(s.i_category_id, w.i_category_id, r.i_category_id) AS i_category_id,
       COALESCE(s.i_category, w.i_category, r.i_category) AS i_category,
       COALESCE(s.store_qty, 0) AS store_quantity,
       COALESCE(w.web_qty, 0) AS web_quantity,
       COALESCE(s.store_qty, 0) + COALESCE(w.web_qty, 0) AS total_quantity,
       r.avg_sentiment,
       r.review_count
FROM store_sales_agg s
FULL OUTER JOIN web_sales_agg w ON s.i_category_id = w.i_category_id AND s.i_category = w.i_category
FULL OUTER JOIN review_agg r ON COALESCE(s.i_category_id, w.i_category_id) = r.i_category_id
    AND COALESCE(s.i_category, w.i_category) = r.i_category
ORDER BY total_quantity DESC
