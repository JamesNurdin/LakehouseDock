WITH store_item_sales AS (
    SELECT
        ss.ss_store_id AS store_id,
        ss.ss_item_id AS item_id,
        ss.ss_quantity AS quantity,
        i.i_price AS price
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
),

store_agg AS (
    SELECT
        sis.store_id,
        SUM(sis.quantity * sis.price) AS store_revenue,
        SUM(sis.quantity) AS store_quantity
    FROM store_item_sales sis
    GROUP BY sis.store_id
),

item_avg_rating AS (
    SELECT
        i.i_item_id AS item_id,
        AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
),

store_item_rating AS (
    SELECT
        sis.store_id,
        AVG(iar.avg_rating) AS avg_item_rating
    FROM store_item_sales sis
    JOIN item_avg_rating iar ON sis.item_id = iar.item_id
    GROUP BY sis.store_id
),

web_item_sales AS (
    SELECT
        ws.ws_item_id AS item_id,
        SUM(ws.ws_quantity) AS web_quantity
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY ws.ws_item_id
),

store_web_sales AS (
    SELECT
        sis.store_id,
        SUM(wis.web_quantity) AS total_web_quantity
    FROM store_item_sales sis
    LEFT JOIN web_item_sales wis ON sis.item_id = wis.item_id
    GROUP BY sis.store_id
),

store_customer_counts AS (
    SELECT
        ss.ss_store_id AS store_id,
        COUNT(DISTINCT c.c_customer_id) AS distinct_customers
    FROM store_sales ss
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    GROUP BY ss.ss_store_id
),

store_customers AS (
    SELECT DISTINCT
        ss.ss_store_id AS store_id,
        ss.ss_customer_id AS customer_id
    FROM store_sales ss
),

web_sales_per_store_customers AS (
    SELECT
        sc.store_id,
        SUM(ws.ws_quantity) AS web_quantity_for_store_customers
    FROM store_customers sc
    JOIN web_sales ws ON sc.customer_id = ws.ws_customer_id
    GROUP BY sc.store_id
)

SELECT
    s.s_store_id,
    s.s_store_name,
    sa.store_revenue,
    sa.store_quantity,
    sir.avg_item_rating,
    sws.total_web_quantity,
    scc.distinct_customers,
    wssc.web_quantity_for_store_customers
FROM stores s
JOIN store_agg sa ON s.s_store_id = sa.store_id
LEFT JOIN store_item_rating sir ON s.s_store_id = sir.store_id
LEFT JOIN store_web_sales sws ON s.s_store_id = sws.store_id
LEFT JOIN store_customer_counts scc ON s.s_store_id = scc.store_id
LEFT JOIN web_sales_per_store_customers wssc ON s.s_store_id = wssc.store_id
ORDER BY sa.store_revenue DESC
LIMIT 10
