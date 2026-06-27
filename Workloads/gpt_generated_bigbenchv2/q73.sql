WITH sales_agg AS (
    SELECT
        ss.ss_store_id,
        s.s_store_name,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_revenue,
        COUNT(DISTINCT c.c_customer_id) AS distinct_customer_count
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    GROUP BY ss.ss_store_id, s.s_store_name
),
rating_per_item AS (
    SELECT
        i.i_item_id,
        AVG(pr.pr_rating) AS item_avg_rating
    FROM items i
    JOIN product_reviews pr ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
rating_agg AS (
    SELECT
        ss.ss_store_id,
        AVG(rpi.item_avg_rating) AS avg_rating
    FROM store_sales ss
    JOIN rating_per_item rpi ON ss.ss_item_id = rpi.i_item_id
    GROUP BY ss.ss_store_id
)
SELECT
    sa.ss_store_id,
    sa.s_store_name,
    sa.total_quantity,
    sa.total_revenue,
    sa.distinct_customer_count,
    ra.avg_rating
FROM sales_agg sa
LEFT JOIN rating_agg ra ON sa.ss_store_id = ra.ss_store_id
ORDER BY sa.total_revenue DESC
