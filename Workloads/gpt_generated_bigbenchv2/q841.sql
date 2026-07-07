WITH
store_agg AS (
    SELECT
        i.i_category_id,
        i.i_category,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue,
        COUNT(DISTINCT ss.ss_customer_id) AS store_customer_cnt
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
web_agg AS (
    SELECT
        i.i_category_id,
        i.i_category,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS web_revenue,
        COUNT(DISTINCT ws.ws_customer_id) AS web_customer_cnt
    FROM web_sales ws
    JOIN items i
        ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
review_agg AS (
    SELECT
        i.i_category_id,
        i.i_category,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(pr.pr_review_id) AS review_cnt
    FROM product_reviews pr
    JOIN items i
        ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
)
SELECT
    COALESCE(s.i_category_id, w.i_category_id, r.i_category_id) AS category_id,
    COALESCE(s.i_category, w.i_category, r.i_category) AS category_name,
    COALESCE(s.store_quantity, 0) AS store_quantity,
    COALESCE(w.web_quantity, 0) AS web_quantity,
    COALESCE(s.store_quantity, 0) + COALESCE(w.web_quantity, 0) AS total_quantity,
    COALESCE(s.store_revenue, 0) AS store_revenue,
    COALESCE(w.web_revenue, 0) AS web_revenue,
    COALESCE(s.store_revenue, 0) + COALESCE(w.web_revenue, 0) AS total_revenue,
    COALESCE(s.store_customer_cnt, 0) + COALESCE(w.web_customer_cnt, 0) AS total_customers,
    r.avg_sentiment,
    COALESCE(r.review_cnt, 0) AS review_cnt
FROM store_agg s
FULL OUTER JOIN web_agg w
    ON s.i_category_id = w.i_category_id AND s.i_category = w.i_category
FULL OUTER JOIN review_agg r
    ON COALESCE(s.i_category_id, w.i_category_id) = r.i_category_id
    AND COALESCE(s.i_category, w.i_category) = r.i_category
ORDER BY total_revenue DESC
