WITH store_sales_agg AS (
    SELECT i.i_category,
           SUM(ss.ss_quantity) AS store_qty
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category
),
web_sales_agg AS (
    SELECT i.i_category,
           SUM(ws.ws_quantity) AS web_qty
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category
),
review_agg AS (
    SELECT i.i_category,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category
),
item_price_agg AS (
    SELECT i.i_category,
           AVG(i.i_price) AS avg_price
    FROM items i
    GROUP BY i.i_category
)
SELECT
    COALESCE(s.i_category, w.i_category, r.i_category, p.i_category) AS category,
    COALESCE(s.store_qty, 0) AS store_quantity,
    COALESCE(w.web_qty, 0) AS web_quantity,
    COALESCE(s.store_qty, 0) + COALESCE(w.web_qty, 0) AS total_quantity,
    p.avg_price,
    r.avg_sentiment,
    r.review_count
FROM store_sales_agg s
FULL OUTER JOIN web_sales_agg w ON s.i_category = w.i_category
FULL OUTER JOIN review_agg r ON COALESCE(s.i_category, w.i_category) = r.i_category
FULL OUTER JOIN item_price_agg p ON COALESCE(s.i_category, w.i_category, r.i_category) = p.i_category
ORDER BY total_quantity DESC
LIMIT 10
