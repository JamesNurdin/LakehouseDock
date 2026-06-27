WITH item_ratings AS (
    SELECT
        i.i_item_id,
        AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    JOIN items i
        ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
store_sales_enriched AS (
    SELECT
        ss.ss_store_id,
        s.s_store_name,
        ss.ss_customer_id,
        ss.ss_item_id,
        i.i_category_name,
        ss.ss_quantity,
        i.i_price,
        ir.avg_rating
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    LEFT JOIN item_ratings ir
        ON ss.ss_item_id = ir.i_item_id
    JOIN stores s
        ON ss.ss_store_id = s.s_store_id
    JOIN customers c
        ON ss.ss_customer_id = c.c_customer_id
)
SELECT
    ss_enriched.s_store_name,
    ss_enriched.i_category_name,
    SUM(ss_enriched.ss_quantity) AS total_quantity,
    SUM(ss_enriched.ss_quantity * ss_enriched.i_price) AS total_revenue,
    AVG(ss_enriched.i_price) AS avg_price,
    AVG(ss_enriched.avg_rating) AS avg_item_rating,
    COUNT(DISTINCT ss_enriched.ss_customer_id) AS distinct_customers
FROM store_sales_enriched ss_enriched
GROUP BY ss_enriched.s_store_name, ss_enriched.i_category_name
HAVING SUM(ss_enriched.ss_quantity * ss_enriched.i_price) > 1000
ORDER BY total_revenue DESC
LIMIT 100
