WITH store_qty AS (
    SELECT i.i_category AS i_category,
           SUM(ss.ss_quantity) AS store_quantity
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category
),
web_qty AS (
    SELECT i.i_category AS i_category,
           SUM(ws.ws_quantity) AS web_quantity
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category
),
review_sentiment AS (
    SELECT i.i_category AS i_category,
           AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category
)
SELECT COALESCE(sq.i_category, wq.i_category, rs.i_category) AS category,
       sq.store_quantity,
       wq.web_quantity,
       rs.avg_sentiment
FROM store_qty sq
FULL OUTER JOIN web_qty wq
    ON sq.i_category = wq.i_category
FULL OUTER JOIN review_sentiment rs
    ON COALESCE(sq.i_category, wq.i_category) = rs.i_category
ORDER BY category
