WITH store_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        s.s_store_id,
        s.s_store_name,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    GROUP BY i.i_category_id, i.i_category_name, s.s_store_id, s.s_store_name
),
store_category_agg AS (
    SELECT
        i_category_id,
        i_category_name,
        SUM(store_quantity) AS total_store_quantity,
        SUM(store_revenue) AS total_store_revenue
    FROM store_agg
    GROUP BY i_category_id, i_category_name
),
web_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS web_revenue
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
review_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
top_store_per_category AS (
    SELECT
        i_category_id,
        i_category_name,
        s_store_name,
        store_quantity,
        ROW_NUMBER() OVER (PARTITION BY i_category_id ORDER BY store_quantity DESC) AS rn
    FROM store_agg
),
customer_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        COUNT(DISTINCT cs.c_customer_id) AS total_customers
    FROM (
        SELECT ss.ss_customer_id AS c_customer_id, ss.ss_item_id AS i_item_id
        FROM store_sales ss
        UNION ALL
        SELECT ws.ws_customer_id AS c_customer_id, ws.ws_item_id AS i_item_id
        FROM web_sales ws
    ) cs
    JOIN customers c ON cs.c_customer_id = c.c_customer_id
    JOIN items i ON cs.i_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
)
SELECT
    sc.i_category_id,
    sc.i_category_name,
    sc.total_store_quantity,
    sc.total_store_revenue,
    wa.web_quantity,
    wa.web_revenue,
    (sc.total_store_quantity + wa.web_quantity) AS total_quantity,
    (sc.total_store_revenue + wa.web_revenue) AS total_revenue,
    ra.avg_rating,
    ra.review_count,
    ca.total_customers,
    tspc.s_store_name AS top_store,
    tspc.store_quantity AS top_store_quantity
FROM store_category_agg sc
LEFT JOIN web_agg wa
    ON sc.i_category_id = wa.i_category_id
LEFT JOIN review_agg ra
    ON sc.i_category_id = ra.i_category_id
LEFT JOIN customer_agg ca
    ON sc.i_category_id = ca.i_category_id
LEFT JOIN (
    SELECT i_category_id, i_category_name, s_store_name, store_quantity
    FROM top_store_per_category
    WHERE rn = 1
) tspc
    ON sc.i_category_id = tspc.i_category_id
ORDER BY total_revenue DESC
LIMIT 20
