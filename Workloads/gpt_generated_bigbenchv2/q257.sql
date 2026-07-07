WITH store_sales_agg AS (
    SELECT
        i.i_category_id AS category_id,
        i.i_category AS category_name,
        SUM(ss.ss_quantity) AS total_store_quantity
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
web_sales_agg AS (
    SELECT
        i.i_category_id AS category_id,
        i.i_category AS category_name,
        SUM(ws.ws_quantity) AS total_web_quantity
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
sales_agg AS (
    SELECT
        COALESCE(s.category_id, w.category_id) AS category_id,
        COALESCE(s.category_name, w.category_name) AS category_name,
        COALESCE(s.total_store_quantity, 0) + COALESCE(w.total_web_quantity, 0) AS total_quantity
    FROM store_sales_agg s
    FULL OUTER JOIN web_sales_agg w
        ON s.category_id = w.category_id
),
review_agg AS (
    SELECT
        i.i_category_id AS category_id,
        AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id
)
SELECT
    s.category_id,
    s.category_name,
    s.total_quantity,
    r.avg_sentiment
FROM sales_agg s
LEFT JOIN review_agg r
    ON s.category_id = r.category_id
ORDER BY s.total_quantity DESC
LIMIT 5
