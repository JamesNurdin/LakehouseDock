WITH category_ratings AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
store_category_sales AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        i.i_category_id,
        i.i_category_name,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_revenue,
        COUNT(DISTINCT ss.ss_customer_id) AS distinct_customers
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    GROUP BY s.s_store_id, s.s_store_name, i.i_category_id, i.i_category_name
)
SELECT
    scs.s_store_id,
    scs.s_store_name,
    scs.i_category_name,
    scs.total_quantity,
    scs.total_revenue,
    scs.distinct_customers,
    cr.avg_rating,
    cr.review_count
FROM store_category_sales scs
LEFT JOIN category_ratings cr
  ON scs.i_category_id = cr.i_category_id
 AND scs.i_category_name = cr.i_category_name
ORDER BY scs.total_revenue DESC
LIMIT 20
