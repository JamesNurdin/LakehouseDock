WITH store_item_sales AS (
    SELECT
        ss.ss_store_id,
        ss.ss_item_id,
        SUM(ss.ss_quantity) AS item_quantity,
        SUM(ss.ss_quantity * i.i_price) AS item_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_store_id, ss.ss_item_id
),
item_reviews AS (
    SELECT
        i.i_item_id,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(pr.pr_review_id) AS review_count
    FROM items i
    LEFT JOIN product_reviews pr ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
store_agg AS (
    SELECT
        sis.ss_store_id,
        SUM(sis.item_revenue) AS total_revenue,
        SUM(sis.item_quantity) AS total_quantity,
        AVG(ir.avg_rating) AS avg_item_rating,
        SUM(ir.review_count) AS total_review_count
    FROM store_item_sales sis
    JOIN item_reviews ir ON ir.i_item_id = sis.ss_item_id
    GROUP BY sis.ss_store_id
),
store_customers AS (
    SELECT
        ss.ss_store_id,
        COUNT(DISTINCT ss.ss_customer_id) AS distinct_customers
    FROM store_sales ss
    GROUP BY ss.ss_store_id
)
SELECT
    s.s_store_id,
    s.s_store_name,
    sa.total_revenue,
    sa.total_quantity,
    sc.distinct_customers,
    sa.avg_item_rating,
    sa.total_review_count
FROM store_agg sa
JOIN store_customers sc ON sa.ss_store_id = sc.ss_store_id
JOIN stores s ON sa.ss_store_id = s.s_store_id
ORDER BY sa.total_revenue DESC
LIMIT 10
