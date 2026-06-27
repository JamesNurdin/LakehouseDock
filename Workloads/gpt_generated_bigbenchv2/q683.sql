WITH store_item_sales AS (
    SELECT
        ss.ss_store_id AS store_id,
        i.i_category_name AS category_name,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_revenue
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_store_id, i.i_category_name
),
store_item_ratings AS (
    SELECT
        ss.ss_store_id AS store_id,
        i.i_category_name AS category_name,
        AVG(pr.pr_rating) AS avg_rating
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    JOIN product_reviews pr
        ON pr.pr_item_id = i.i_item_id
    GROUP BY ss.ss_store_id, i.i_category_name
)
SELECT
    s.s_store_id,
    s.s_store_name,
    sis.category_name,
    COALESCE(sis.total_quantity, 0) AS total_quantity,
    COALESCE(sis.total_revenue, 0) AS total_revenue,
    COALESCE(sir.avg_rating, 0) AS avg_rating
FROM stores s
LEFT JOIN store_item_sales sis
    ON sis.store_id = s.s_store_id
LEFT JOIN store_item_ratings sir
    ON sir.store_id = s.s_store_id
    AND sir.category_name = sis.category_name
ORDER BY total_revenue DESC
LIMIT 10
