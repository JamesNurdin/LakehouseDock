WITH store_agg AS (
    SELECT
        ss.ss_store_id AS store_id,
        s.s_store_name AS store_name,
        i.i_item_id AS item_id,
        i.i_category_name AS category_name,
        i.i_price AS price,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue,
        COUNT(DISTINCT ss.ss_customer_id) AS store_customer_count
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    GROUP BY ss.ss_store_id, s.s_store_name, i.i_item_id, i.i_category_name, i.i_price
),
web_agg AS (
    SELECT
        NULL AS store_id,
        'Online' AS store_name,
        i.i_item_id AS item_id,
        i.i_category_name AS category_name,
        i.i_price AS price,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS web_revenue,
        COUNT(DISTINCT ws.ws_customer_id) AS web_customer_count
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_item_id, i.i_category_name, i.i_price
),
rating_agg AS (
    SELECT
        i.i_item_id AS item_id,
        AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
combined AS (
    SELECT
        COALESCE(sa.store_id, wa.store_id) AS store_id,
        COALESCE(sa.store_name, wa.store_name) AS store_name,
        COALESCE(sa.item_id, wa.item_id) AS item_id,
        COALESCE(sa.category_name, wa.category_name) AS category_name,
        COALESCE(sa.price, wa.price) AS price,
        COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0) AS total_quantity,
        COALESCE(sa.store_revenue, 0) + COALESCE(wa.web_revenue, 0) AS total_revenue,
        COALESCE(sa.store_customer_count, 0) + COALESCE(wa.web_customer_count, 0) AS total_customer_count,
        r.avg_rating
    FROM store_agg sa
    FULL OUTER JOIN web_agg wa ON sa.item_id = wa.item_id
    LEFT JOIN rating_agg r ON COALESCE(sa.item_id, wa.item_id) = r.item_id
)
SELECT
    store_name,
    category_name,
    price,
    total_quantity,
    total_revenue,
    total_customer_count,
    avg_rating
FROM combined
WHERE total_quantity > 0
ORDER BY total_revenue DESC
LIMIT 100
