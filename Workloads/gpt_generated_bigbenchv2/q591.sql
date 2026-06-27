WITH item_ratings AS (
    SELECT pr_item_id AS i_item_id,
           avg(pr_rating) AS avg_rating
    FROM product_reviews
    GROUP BY pr_item_id
),
store_sales_agg AS (
    SELECT
        ss.ss_store_id AS store_id,
        i.i_category_name,
        sum(ss.ss_quantity) AS store_quantity,
        sum(ss.ss_quantity * i.i_price) AS store_revenue,
        avg(ir.avg_rating) AS avg_rating
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    LEFT JOIN item_ratings ir
        ON i.i_item_id = ir.i_item_id
    GROUP BY ss.ss_store_id, i.i_category_name
),
web_sales_agg AS (
    SELECT
        CAST(NULL AS bigint) AS store_id,
        i.i_category_name,
        sum(ws.ws_quantity) AS web_quantity,
        sum(ws.ws_quantity * i.i_price) AS web_revenue,
        avg(ir.avg_rating) AS avg_rating
    FROM web_sales ws
    JOIN items i
        ON ws.ws_item_id = i.i_item_id
    LEFT JOIN item_ratings ir
        ON i.i_item_id = ir.i_item_id
    GROUP BY i.i_category_name
)
SELECT
    COALESCE(s.s_store_name, 'Online') AS store_name,
    COALESCE(sa.i_category_name, wa.i_category_name) AS category_name,
    COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0) AS total_quantity,
    COALESCE(sa.store_revenue, 0) + COALESCE(wa.web_revenue, 0) AS total_revenue,
    COALESCE(sa.avg_rating, wa.avg_rating) AS avg_item_rating
FROM store_sales_agg sa
FULL OUTER JOIN web_sales_agg wa
    ON sa.i_category_name = wa.i_category_name
LEFT JOIN stores s
    ON sa.store_id = s.s_store_id
ORDER BY total_revenue DESC
LIMIT 50
