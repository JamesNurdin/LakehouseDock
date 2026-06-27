WITH review_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
store_agg AS (
    SELECT
        ss.ss_store_id,
        s.s_store_name,
        i.i_category_id,
        i.i_category_name,
        SUM(ss.ss_quantity) AS total_quantity,
        COUNT(DISTINCT ss.ss_customer_id) AS distinct_customers
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    GROUP BY ss.ss_store_id, s.s_store_name, i.i_category_id, i.i_category_name
)
SELECT
    sa.ss_store_id AS store_id,
    sa.s_store_name AS store_name,
    sa.i_category_id AS category_id,
    sa.i_category_name AS category_name,
    sa.total_quantity,
    sa.distinct_customers,
    ra.avg_rating
FROM store_agg sa
LEFT JOIN review_agg ra
    ON sa.i_category_id = ra.i_category_id
   AND sa.i_category_name = ra.i_category_name
WHERE ra.avg_rating IS NOT NULL
  AND ra.avg_rating >= 4
ORDER BY sa.total_quantity DESC
