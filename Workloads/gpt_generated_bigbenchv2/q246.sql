WITH store_sales_agg AS (
    SELECT i.i_category AS category,
           SUM(ss.ss_quantity) AS total_store_quantity
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category
),
web_sales_agg AS (
    SELECT i.i_category AS category,
           SUM(ws.ws_quantity) AS total_web_quantity
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category
),
review_agg AS (
    SELECT i.i_category AS category,
           AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category
)
SELECT 
    COALESCE(s.category, w.category, r.category) AS category,
    s.total_store_quantity,
    w.total_web_quantity,
    r.avg_sentiment
FROM store_sales_agg s
FULL OUTER JOIN web_sales_agg w ON s.category = w.category
FULL OUTER JOIN review_agg r ON COALESCE(s.category, w.category) = r.category
ORDER BY category
