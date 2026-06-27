WITH item_ratings AS (
    SELECT
        pr_item_id,
        AVG(pr_rating) AS avg_rating
    FROM product_reviews
    GROUP BY pr_item_id
),
store_aggregates AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_revenue,
        SUM(ss.ss_quantity * COALESCE(ir.avg_rating, 0)) / SUM(ss.ss_quantity) AS weighted_avg_rating,
        COUNT(DISTINCT ss.ss_customer_id) AS distinct_customers
    FROM store_sales ss
    JOIN stores s
        ON ss.ss_store_id = s.s_store_id
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    LEFT JOIN item_ratings ir
        ON i.i_item_id = ir.pr_item_id
    GROUP BY s.s_store_id, s.s_store_name
),
category_sales AS (
    SELECT
        ss.ss_store_id,
        i.i_category_name,
        SUM(ss.ss_quantity) AS category_quantity
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_store_id, i.i_category_name
),
ranked_categories AS (
    SELECT
        cs.ss_store_id,
        cs.i_category_name,
        cs.category_quantity,
        ROW_NUMBER() OVER (PARTITION BY cs.ss_store_id ORDER BY cs.category_quantity DESC) AS rn
    FROM category_sales cs
)
SELECT
    sa.s_store_name,
    sa.total_quantity,
    sa.total_revenue,
    sa.weighted_avg_rating,
    sa.distinct_customers,
    rc.i_category_name AS top_category,
    rc.category_quantity AS top_category_quantity
FROM store_aggregates sa
LEFT JOIN ranked_categories rc
    ON sa.s_store_id = rc.ss_store_id
   AND rc.rn = 1
ORDER BY sa.total_revenue DESC
