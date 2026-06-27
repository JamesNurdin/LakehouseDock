WITH store_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue,
        COUNT(DISTINCT ss.ss_customer_id) AS store_customer_cnt
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
web_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS web_revenue,
        COUNT(DISTINCT ws.ws_customer_id) AS web_customer_cnt
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
review_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        COUNT(pr.pr_review_id) AS review_cnt,
        AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
combined AS (
    SELECT
        COALESCE(s.i_category_id, w.i_category_id, r.i_category_id) AS category_id,
        COALESCE(s.i_category_name, w.i_category_name, r.i_category_name) AS category_name,
        COALESCE(s.store_quantity, 0) + COALESCE(w.web_quantity, 0) AS total_quantity,
        COALESCE(s.store_revenue, 0) + COALESCE(w.web_revenue, 0) AS total_revenue,
        COALESCE(s.store_customer_cnt, 0) + COALESCE(w.web_customer_cnt, 0) AS total_customer_cnt,
        COALESCE(r.review_cnt, 0) AS review_count,
        COALESCE(r.avg_rating, 0) AS avg_rating
    FROM store_agg s
    FULL OUTER JOIN web_agg w ON s.i_category_id = w.i_category_id
    FULL OUTER JOIN review_agg r ON COALESCE(s.i_category_id, w.i_category_id) = r.i_category_id
)
SELECT
    category_id,
    category_name,
    total_quantity,
    total_revenue,
    total_customer_cnt,
    review_count,
    avg_rating,
    ROW_NUMBER() OVER (ORDER BY total_revenue DESC) AS revenue_rank
FROM combined
ORDER BY revenue_rank
LIMIT 10
