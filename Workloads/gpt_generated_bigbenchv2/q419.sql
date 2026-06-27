WITH item_avg_rating AS (
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
        ss.ss_item_id,
        i.i_category_id,
        i.i_category_name,
        ss.ss_quantity,
        i.i_price,
        ar.avg_rating,
        ss.ss_customer_id
    FROM store_sales ss
    JOIN stores s
        ON ss.ss_store_id = s.s_store_id
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    LEFT JOIN item_avg_rating ar
        ON i.i_item_id = ar.i_item_id
)
SELECT
    sse.ss_store_id,
    sse.s_store_name,
    sse.i_category_id,
    sse.i_category_name,
    SUM(sse.ss_quantity) AS total_quantity,
    SUM(sse.ss_quantity * sse.i_price) AS total_revenue,
    CASE
        WHEN SUM(sse.ss_quantity) > 0 THEN SUM(sse.ss_quantity * COALESCE(sse.avg_rating, 0)) / SUM(sse.ss_quantity)
        ELSE NULL
    END AS weighted_avg_rating,
    COUNT(DISTINCT sse.ss_customer_id) AS distinct_customers
FROM store_sales_enriched sse
GROUP BY
    sse.ss_store_id,
    sse.s_store_name,
    sse.i_category_id,
    sse.i_category_name
ORDER BY total_revenue DESC
LIMIT 10
