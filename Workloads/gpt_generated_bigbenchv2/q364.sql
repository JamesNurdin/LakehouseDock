WITH store_agg AS (
    SELECT
        ss.ss_item_id AS i_item_id,
        ss.ss_store_id AS s_store_id,
        SUM(ss.ss_quantity) AS total_store_quantity,
        COUNT(DISTINCT ss.ss_customer_id) AS distinct_store_customers
    FROM store_sales ss
    GROUP BY ss.ss_item_id, ss.ss_store_id
),
store_total AS (
    SELECT
        ss.ss_item_id AS i_item_id,
        SUM(ss.ss_quantity) AS total_store_quantity,
        COUNT(DISTINCT ss.ss_customer_id) AS distinct_store_customers
    FROM store_sales ss
    GROUP BY ss.ss_item_id
),
store_top AS (
    SELECT
        sa.i_item_id,
        sa.s_store_id,
        sa.total_store_quantity,
        ROW_NUMBER() OVER (PARTITION BY sa.i_item_id ORDER BY sa.total_store_quantity DESC) AS rn
    FROM store_agg sa
),
web_agg AS (
    SELECT
        ws.ws_item_id AS i_item_id,
        SUM(ws.ws_quantity) AS total_web_quantity,
        COUNT(DISTINCT ws.ws_customer_id) AS distinct_web_customers
    FROM web_sales ws
    GROUP BY ws.ws_item_id
),
review_agg AS (
    SELECT
        pr.pr_item_id AS i_item_id,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(*) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
),
item_info AS (
    SELECT
        i.i_item_id,
        i.i_name,
        i.i_category_name,
        i.i_price
    FROM items i
)
SELECT
    ii.i_item_id,
    ii.i_name,
    ii.i_category_name,
    ii.i_price,
    COALESCE(st.total_store_quantity, 0) + COALESCE(wa.total_web_quantity, 0) AS total_quantity_sold,
    COALESCE(st.distinct_store_customers, 0) + COALESCE(wa.distinct_web_customers, 0) AS total_distinct_customers,
    ra.avg_rating,
    ra.review_count,
    s.s_store_name AS top_store_name,
    COALESCE(st_top.total_store_quantity, 0) AS top_store_quantity
FROM item_info ii
LEFT JOIN store_total st
    ON st.i_item_id = ii.i_item_id
LEFT JOIN web_agg wa
    ON wa.i_item_id = ii.i_item_id
LEFT JOIN review_agg ra
    ON ra.i_item_id = ii.i_item_id
LEFT JOIN store_top st_top
    ON st_top.i_item_id = ii.i_item_id AND st_top.rn = 1
LEFT JOIN stores s
    ON s.s_store_id = st_top.s_store_id
ORDER BY total_quantity_sold DESC
LIMIT 10
