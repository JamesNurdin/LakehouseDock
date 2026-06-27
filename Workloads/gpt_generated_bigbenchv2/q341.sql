WITH item_ratings AS (
    SELECT
        i.i_item_id,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
store_sales_enriched AS (
    SELECT
        s.s_store_id AS s_store_id,
        s.s_store_name AS s_store_name,
        ss.ss_customer_id AS ss_customer_id,
        ss.ss_item_id AS ss_item_id,
        i.i_price AS i_price,
        ss.ss_quantity AS ss_quantity,
        ir.avg_rating AS avg_rating,
        ir.review_count AS review_count
    FROM store_sales ss
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
    LEFT JOIN item_ratings ir ON ss.ss_item_id = ir.i_item_id
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
)
SELECT
    s_store_id,
    s_store_name,
    SUM(ss_quantity) AS total_quantity_sold,
    SUM(ss_quantity * i_price) AS total_revenue,
    COUNT(DISTINCT ss_customer_id) AS distinct_customers,
    COUNT(DISTINCT ss_item_id) AS distinct_items_sold,
    AVG(avg_rating) AS avg_item_rating,
    SUM(review_count) AS total_reviews
FROM store_sales_enriched
GROUP BY s_store_id, s_store_name
ORDER BY total_revenue DESC
