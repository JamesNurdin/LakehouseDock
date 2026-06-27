WITH item_ratings AS (
    SELECT
        i.i_item_id,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
customer_total_quantity AS (
    SELECT
        c_id AS c_customer_id,
        SUM(quantity) AS total_quantity
    FROM (
        SELECT ss_customer_id AS c_id, ss_quantity AS quantity FROM store_sales
        UNION ALL
        SELECT ws_customer_id AS c_id, ws_quantity AS quantity FROM web_sales
    ) t
    GROUP BY c_id
),
store_metrics AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_revenue,
        COUNT(DISTINCT ss.ss_customer_id) AS distinct_customers,
        AVG(ir.avg_rating) AS avg_item_rating,
        SUM(ir.review_count) AS total_reviews,
        AVG(ctq.total_quantity) AS avg_customer_total_quantity
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    LEFT JOIN item_ratings ir ON i.i_item_id = ir.i_item_id
    LEFT JOIN customer_total_quantity ctq ON ss.ss_customer_id = ctq.c_customer_id
    GROUP BY s.s_store_id, s.s_store_name
)
SELECT
    s_store_id,
    s_store_name,
    total_quantity,
    total_revenue,
    distinct_customers,
    avg_item_rating,
    total_reviews,
    avg_customer_total_quantity
FROM store_metrics
ORDER BY total_revenue DESC
LIMIT 10
