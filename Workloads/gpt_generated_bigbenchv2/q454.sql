WITH store_agg AS (
    SELECT
        i.i_category_id AS category_id,
        i.i_category AS category,
        SUM(ss.ss_quantity) AS store_quantity,
        COUNT(DISTINCT ss.ss_customer_id) AS store_customer_count
    FROM store_sales ss
    INNER JOIN customers c
        ON ss.ss_customer_id = c.c_customer_id
    INNER JOIN items i
        ON ss.ss_item_id = i.i_item_id
    INNER JOIN stores s
        ON ss.ss_store_id = s.s_store_id
    GROUP BY i.i_category_id, i.i_category
),
web_agg AS (
    SELECT
        i.i_category_id AS category_id,
        i.i_category AS category,
        SUM(ws.ws_quantity) AS web_quantity,
        COUNT(DISTINCT ws.ws_customer_id) AS web_customer_count
    FROM web_sales ws
    INNER JOIN customers c
        ON ws.ws_customer_id = c.c_customer_id
    INNER JOIN items i
        ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
review_agg AS (
    SELECT
        i.i_category_id AS category_id,
        i.i_category AS category,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    INNER JOIN items i
        ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
)
SELECT
    COALESCE(s.category_id, w.category_id, r.category_id) AS category_id,
    COALESCE(s.category, w.category, r.category) AS category,
    COALESCE(s.store_quantity, 0) AS store_quantity,
    COALESCE(w.web_quantity, 0) AS web_quantity,
    COALESCE(s.store_quantity, 0) + COALESCE(w.web_quantity, 0) AS total_quantity,
    COALESCE(s.store_customer_count, 0) AS store_customer_count,
    COALESCE(w.web_customer_count, 0) AS web_customer_count,
    r.avg_sentiment,
    COALESCE(r.review_count, 0) AS review_count
FROM store_agg s
FULL OUTER JOIN web_agg w
    ON s.category_id = w.category_id
FULL OUTER JOIN review_agg r
    ON COALESCE(s.category_id, w.category_id) = r.category_id
ORDER BY total_quantity DESC
LIMIT 20
