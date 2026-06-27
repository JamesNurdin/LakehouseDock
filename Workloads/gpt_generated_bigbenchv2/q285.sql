WITH rating_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
store_sales_agg AS (
    SELECT
        s.s_store_name,
        i.i_category_id,
        i.i_category_name,
        SUM(ss.ss_quantity) AS total_store_quantity,
        SUM(i.i_price * ss.ss_quantity) AS total_store_revenue,
        COUNT(DISTINCT i.i_item_id) AS distinct_items_sold
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    GROUP BY s.s_store_name, i.i_category_id, i.i_category_name
),
web_sales_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        SUM(ws.ws_quantity) AS total_web_quantity
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
)
SELECT
    ss.s_store_name,
    ss.i_category_id,
    ss.i_category_name,
    ss.total_store_quantity,
    ss.total_store_revenue,
    COALESCE(ws.total_web_quantity, 0) AS total_web_quantity,
    ss.distinct_items_sold,
    COALESCE(r.avg_rating, 0) AS avg_rating
FROM store_sales_agg ss
LEFT JOIN web_sales_agg ws
    ON ss.i_category_id = ws.i_category_id
    AND ss.i_category_name = ws.i_category_name
LEFT JOIN rating_agg r
    ON ss.i_category_id = r.i_category_id
    AND ss.i_category_name = r.i_category_name
ORDER BY ss.s_store_name, ss.i_category_id
