WITH store_sales_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        i.i_category_id,
        i.i_category_name,
        SUM(ss.ss_quantity) AS store_quantity,
        COUNT(DISTINCT ss.ss_customer_id) AS store_customer_count
    FROM store_sales ss
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY s.s_store_id, s.s_store_name, i.i_category_id, i.i_category_name
),
web_sales_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        SUM(ws.ws_quantity) AS web_quantity,
        COUNT(DISTINCT ws.ws_customer_id) AS web_customer_count
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
product_ratings AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(*) AS rating_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
)
SELECT
    ss.s_store_id,
    ss.s_store_name,
    ss.i_category_id,
    ss.i_category_name,
    ss.store_quantity,
    COALESCE(ws.web_quantity, 0) AS web_quantity,
    ss.store_customer_count,
    COALESCE(ws.web_customer_count, 0) AS web_customer_count,
    COALESCE(r.avg_rating, 0) AS avg_rating,
    COALESCE(r.rating_count, 0) AS rating_count,
    (ss.store_quantity + COALESCE(ws.web_quantity, 0)) AS total_quantity,
    (ss.store_customer_count + COALESCE(ws.web_customer_count, 0)) AS total_customer_count
FROM store_sales_agg ss
LEFT JOIN web_sales_agg ws
    ON ss.i_category_id = ws.i_category_id
LEFT JOIN product_ratings r
    ON ss.i_category_id = r.i_category_id
ORDER BY total_quantity DESC
LIMIT 20
