WITH item_ratings AS (
    SELECT pr.pr_item_id,
           AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT
    s_store_name,
    i_category_name,
    total_quantity,
    distinct_customers,
    avg_item_rating
FROM (
    SELECT
        s.s_store_name AS s_store_name,
        i.i_category_name AS i_category_name,
        SUM(ss.ss_quantity) AS total_quantity,
        COUNT(DISTINCT ss.ss_customer_id) AS distinct_customers,
        AVG(COALESCE(ir.avg_rating, 0)) AS avg_item_rating
    FROM store_sales ss
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
    LEFT JOIN item_ratings ir ON i.i_item_id = ir.pr_item_id
    GROUP BY s.s_store_name, i.i_category_name

    UNION ALL

    SELECT
        'Online' AS s_store_name,
        i.i_category_name AS i_category_name,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws.ws_customer_id) AS distinct_customers,
        AVG(COALESCE(ir.avg_rating, 0)) AS avg_item_rating
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    LEFT JOIN item_ratings ir ON i.i_item_id = ir.pr_item_id
    GROUP BY i.i_category_name
) AS combined
ORDER BY s_store_name, i_category_name
