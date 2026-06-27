WITH store_agg AS (
    SELECT
        i.i_item_id,
        i.i_name,
        i.i_category_name,
        i.i_price,
        SUM(ss.ss_quantity) AS total_store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_store_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    GROUP BY i.i_item_id, i.i_name, i.i_category_name, i.i_price
),
web_agg AS (
    SELECT
        i.i_item_id,
        i.i_name,
        i.i_category_name,
        i.i_price,
        SUM(ws.ws_quantity) AS total_web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS total_web_revenue
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    GROUP BY i.i_item_id, i.i_name, i.i_category_name, i.i_price
),
review_agg AS (
    SELECT
        i.i_item_id,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
)
SELECT
    i.i_item_id,
    i.i_name,
    i.i_category_name,
    i.i_price,
    COALESCE(s.total_store_quantity, 0) AS total_store_quantity,
    COALESCE(s.total_store_revenue, 0) AS total_store_revenue,
    COALESCE(w.total_web_quantity, 0) AS total_web_quantity,
    COALESCE(w.total_web_revenue, 0) AS total_web_revenue,
    COALESCE(r.avg_rating, 0) AS avg_rating,
    COALESCE(r.review_count, 0) AS review_count,
    (COALESCE(s.total_store_quantity, 0) + COALESCE(w.total_web_quantity, 0)) AS total_quantity_sold
FROM items i
LEFT JOIN store_agg s ON i.i_item_id = s.i_item_id
LEFT JOIN web_agg w ON i.i_item_id = w.i_item_id
LEFT JOIN review_agg r ON i.i_item_id = r.i_item_id
ORDER BY total_quantity_sold DESC
LIMIT 10
