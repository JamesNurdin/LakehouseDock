WITH category_base AS (
    SELECT DISTINCT i.i_category_id,
                    i.i_category
    FROM items i
),
store_sales_agg AS (
    SELECT i.i_category_id,
           SUM(ss.ss_quantity) AS total_store_quantity
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category_id
),
web_sales_agg AS (
    SELECT i.i_category_id,
           SUM(ws.ws_quantity) AS total_web_quantity
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id
),
review_agg AS (
    SELECT i.i_category_id,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id
)
SELECT
    cb.i_category,
    COALESCE(ssa.total_store_quantity, 0) AS total_store_quantity,
    COALESCE(wsa.total_web_quantity, 0) AS total_web_quantity,
    r.avg_sentiment,
    COALESCE(r.review_count, 0) AS review_count
FROM category_base cb
LEFT JOIN store_sales_agg ssa ON cb.i_category_id = ssa.i_category_id
LEFT JOIN web_sales_agg wsa ON cb.i_category_id = wsa.i_category_id
LEFT JOIN review_agg r ON cb.i_category_id = r.i_category_id
ORDER BY total_store_quantity DESC, total_web_quantity DESC
