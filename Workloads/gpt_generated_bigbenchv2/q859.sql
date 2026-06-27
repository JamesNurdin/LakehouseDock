WITH store_sales_agg AS (
    SELECT
        ss.ss_store_id,
        i.i_item_id,
        i.i_name,
        i.i_category_id,
        i.i_category_name,
        i.i_price,
        SUM(ss.ss_quantity) AS total_store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_store_revenue
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    GROUP BY
        ss.ss_store_id,
        i.i_item_id,
        i.i_name,
        i.i_category_id,
        i.i_category_name,
        i.i_price
),
web_sales_agg AS (
    SELECT
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS total_web_revenue
    FROM web_sales ws
    JOIN items i
        ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
rating_agg AS (
    SELECT
        i.i_item_id,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i
        ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
)
SELECT
    s.s_store_name,
    ss.ss_store_id,
    ss.i_item_id,
    ss.i_name,
    ss.i_category_id,
    ss.i_category_name,
    ss.total_store_quantity,
    ss.total_store_revenue,
    COALESCE(ws.total_web_quantity, 0) AS total_web_quantity,
    COALESCE(ws.total_web_revenue, 0) AS total_web_revenue,
    COALESCE(r.avg_rating, 0) AS avg_rating,
    COALESCE(r.review_count, 0) AS review_count
FROM store_sales_agg ss
JOIN stores s
    ON ss.ss_store_id = s.s_store_id
LEFT JOIN web_sales_agg ws
    ON ss.i_item_id = ws.i_item_id
LEFT JOIN rating_agg r
    ON ss.i_item_id = r.i_item_id
ORDER BY ss.total_store_revenue DESC
LIMIT 100
