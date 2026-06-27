WITH item_avg_rating AS (
    SELECT
        i.i_item_id,
        AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    JOIN items i
        ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
store_item_sales AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        ss.ss_item_id,
        i.i_name,
        i.i_category_name,
        ss.ss_quantity,
        ss.ss_quantity * i.i_price AS revenue,
        ar.avg_rating,
        ss.ss_customer_id
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    JOIN stores s
        ON ss.ss_store_id = s.s_store_id
    JOIN customers c
        ON ss.ss_customer_id = c.c_customer_id
    LEFT JOIN item_avg_rating ar
        ON i.i_item_id = ar.i_item_id
),
store_summary AS (
    SELECT
        s_store_id,
        s_store_name,
        SUM(revenue) AS total_revenue,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_quantity * COALESCE(avg_rating, 0)) / SUM(ss_quantity) AS avg_weighted_rating,
        COUNT(DISTINCT ss_customer_id) AS distinct_customer_count
    FROM store_item_sales
    GROUP BY s_store_id, s_store_name
),
top_items AS (
    SELECT
        s_store_id,
        s_store_name,
        ss_item_id,
        i_name,
        i_category_name,
        revenue,
        ss_quantity,
        ROW_NUMBER() OVER (PARTITION BY s_store_id ORDER BY revenue DESC) AS item_rank
    FROM store_item_sales
)
SELECT
    ss.s_store_id,
    ss.s_store_name,
    ss.total_revenue,
    ss.total_quantity,
    ss.avg_weighted_rating,
    ss.distinct_customer_count,
    ti.item_rank,
    ti.ss_item_id AS item_id,
    ti.i_name AS item_name,
    ti.i_category_name AS item_category,
    ti.revenue AS item_revenue,
    ti.ss_quantity AS item_quantity
FROM store_summary ss
JOIN top_items ti
    ON ss.s_store_id = ti.s_store_id
WHERE ti.item_rank <= 3
ORDER BY ss.s_store_id, ti.item_rank
