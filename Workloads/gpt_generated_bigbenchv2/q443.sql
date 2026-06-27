WITH review_stats AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        i.i_item_id,
        i.i_price,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(pr.pr_review_id) AS review_count
    FROM items i
    LEFT JOIN product_reviews pr
        ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name, i.i_item_id, i.i_price
),
sales_stats AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        i.i_item_id,
        SUM(ss.ss_quantity) AS store_qty,
        SUM(ws.ws_quantity) AS web_qty
    FROM items i
    LEFT JOIN store_sales ss
        ON ss.ss_item_id = i.i_item_id
    LEFT JOIN web_sales ws
        ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name, i.i_item_id
)
SELECT
    rs.i_category_id,
    rs.i_category_name,
    COUNT(DISTINCT rs.i_item_id) AS distinct_items,
    AVG(rs.avg_rating) AS category_avg_rating,
    SUM(COALESCE(s.store_qty, 0) + COALESCE(s.web_qty, 0)) AS total_quantity_sold,
    SUM((COALESCE(s.store_qty, 0) + COALESCE(s.web_qty, 0)) * rs.i_price) AS total_revenue,
    AVG(rs.i_price) AS avg_item_price,
    SUM(rs.review_count) AS total_reviews
FROM review_stats rs
LEFT JOIN sales_stats s
    ON s.i_category_id = rs.i_category_id
    AND s.i_item_id = rs.i_item_id
GROUP BY rs.i_category_id, rs.i_category_name
ORDER BY category_avg_rating DESC
LIMIT 10
