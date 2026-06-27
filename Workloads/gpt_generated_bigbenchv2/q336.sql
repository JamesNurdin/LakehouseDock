WITH store_rev AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue,
        SUM(ss.ss_quantity) AS store_units_sold
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
web_rev AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        SUM(ws.ws_quantity * i.i_price) AS web_revenue,
        SUM(ws.ws_quantity) AS web_units_sold
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
review_stats AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
categories AS (
    SELECT DISTINCT i.i_category_id, i.i_category_name
    FROM items i
)
SELECT
    cat.i_category_id,
    cat.i_category_name,
    COALESCE(sr.store_revenue, 0) + COALESCE(wr.web_revenue, 0) AS total_revenue,
    COALESCE(sr.store_units_sold, 0) + COALESCE(wr.web_units_sold, 0) AS total_units_sold,
    rs.avg_rating,
    rs.review_count
FROM categories cat
LEFT JOIN store_rev sr ON cat.i_category_id = sr.i_category_id
LEFT JOIN web_rev wr ON cat.i_category_id = wr.i_category_id
LEFT JOIN review_stats rs ON cat.i_category_id = rs.i_category_id
ORDER BY total_revenue DESC
LIMIT 10
