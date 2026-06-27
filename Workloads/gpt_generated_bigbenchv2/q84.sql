WITH store_item_sales AS (
    SELECT
        ss.ss_store_id,
        ss.ss_item_id,
        SUM(ss.ss_quantity) AS total_store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_store_revenue
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_store_id, ss.ss_item_id
),
web_item_sales AS (
    SELECT
        ws.ws_item_id,
        SUM(ws.ws_quantity) AS total_web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS total_web_revenue
    FROM web_sales ws
    JOIN items i
        ON ws.ws_item_id = i.i_item_id
    GROUP BY ws.ws_item_id
),
item_ratings AS (
    SELECT
        pr.pr_item_id,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(*) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
),
store_customer_counts AS (
    SELECT
        ss.ss_store_id,
        COUNT(DISTINCT ss.ss_customer_id) AS distinct_customers
    FROM store_sales ss
    JOIN customers c
        ON ss.ss_customer_id = c.c_customer_id
    GROUP BY ss.ss_store_id
),
store_item_details AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        i.i_item_id,
        i.i_name,
        i.i_category_name,
        sis.total_store_quantity,
        sis.total_store_revenue,
        COALESCE(wis.total_web_quantity, 0) AS total_web_quantity,
        COALESCE(wis.total_web_revenue, 0) AS total_web_revenue,
        ir.avg_rating,
        ir.review_count,
        scc.distinct_customers
    FROM store_item_sales sis
    JOIN stores s
        ON sis.ss_store_id = s.s_store_id
    JOIN items i
        ON sis.ss_item_id = i.i_item_id
    LEFT JOIN web_item_sales wis
        ON i.i_item_id = wis.ws_item_id
    LEFT JOIN item_ratings ir
        ON i.i_item_id = ir.pr_item_id
    LEFT JOIN store_customer_counts scc
        ON s.s_store_id = scc.ss_store_id
)
SELECT
    s_store_name,
    i_name,
    i_category_name,
    total_store_quantity,
    total_store_revenue,
    total_web_quantity,
    total_web_revenue,
    avg_rating,
    review_count,
    distinct_customers
FROM (
    SELECT
        s_store_name,
        i_name,
        i_category_name,
        total_store_quantity,
        total_store_revenue,
        total_web_quantity,
        total_web_revenue,
        avg_rating,
        review_count,
        distinct_customers,
        ROW_NUMBER() OVER (PARTITION BY s_store_name ORDER BY total_store_quantity DESC) AS rn
    FROM store_item_details
) ranked
WHERE rn <= 5
ORDER BY s_store_name, rn
