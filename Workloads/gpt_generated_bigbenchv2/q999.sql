WITH store_sales_agg AS (
    SELECT
        ss.ss_store_id,
        s.s_store_name,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_revenue,
        COUNT(DISTINCT ss.ss_customer_id) AS distinct_customer_count,
        COUNT(DISTINCT ss.ss_item_id) AS distinct_items_sold
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    JOIN stores s
        ON ss.ss_store_id = s.s_store_id
    GROUP BY ss.ss_store_id, s.s_store_name
),
store_rating_agg AS (
    SELECT
        ss.ss_store_id,
        AVG(pr.pr_rating) AS avg_item_rating,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i
        ON pr.pr_item_id = i.i_item_id
    JOIN store_sales ss
        ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_store_id
)
SELECT
    s.s_store_id,
    s.s_store_name,
    COALESCE(sa.total_quantity, 0) AS total_quantity_sold,
    COALESCE(sa.total_revenue, 0) AS total_revenue,
    COALESCE(sa.distinct_customer_count, 0) AS distinct_customer_count,
    COALESCE(sa.distinct_items_sold, 0) AS distinct_items_sold,
    COALESCE(sr.avg_item_rating, 0) AS average_item_rating,
    COALESCE(sr.review_count, 0) AS total_review_count
FROM stores s
LEFT JOIN store_sales_agg sa
    ON s.s_store_id = sa.ss_store_id
LEFT JOIN store_rating_agg sr
    ON s.s_store_id = sr.ss_store_id
ORDER BY total_revenue DESC
LIMIT 10
