WITH
    store_sales_agg AS (
        SELECT
            ss.ss_store_id,
            COUNT(DISTINCT ss.ss_customer_id) AS distinct_customers,
            SUM(ss.ss_quantity) AS total_quantity,
            SUM(ss.ss_quantity * i.i_price) AS total_revenue
        FROM store_sales ss
        JOIN items i ON ss.ss_item_id = i.i_item_id
        GROUP BY ss.ss_store_id
    ),
    store_rating_agg AS (
        SELECT
            dsi.ss_store_id,
            AVG(pr.pr_rating) AS avg_rating
        FROM (
            SELECT DISTINCT ss.ss_store_id, ss.ss_item_id
            FROM store_sales ss
        ) dsi
        JOIN items i ON dsi.ss_item_id = i.i_item_id
        JOIN product_reviews pr ON i.i_item_id = pr.pr_item_id
        GROUP BY dsi.ss_store_id
    )
SELECT
    s.s_store_id,
    s.s_store_name,
    sa.distinct_customers,
    sa.total_quantity,
    sa.total_revenue,
    COALESCE(r.avg_rating, 0) AS avg_rating
FROM store_sales_agg sa
JOIN stores s ON sa.ss_store_id = s.s_store_id
LEFT JOIN store_rating_agg r ON sa.ss_store_id = r.ss_store_id
ORDER BY sa.total_revenue DESC
LIMIT 10
