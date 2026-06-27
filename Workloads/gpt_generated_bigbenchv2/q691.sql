WITH item_ratings AS (
    SELECT i.i_item_id,
           AVG(pr.pr_rating) AS avg_rating,
           COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
store_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        i.i_category_id,
        i.i_category_name,
        SUM(ss.ss_quantity) AS total_store_quantity,
        COUNT(DISTINCT ss.ss_customer_id) AS distinct_store_customers,
        AVG(i.i_price) AS avg_item_price,
        AVG(COALESCE(ir.avg_rating, 0)) AS avg_item_rating,
        SUM(COALESCE(ir.review_count, 0)) AS total_review_count
    FROM store_sales ss
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
    LEFT JOIN item_ratings ir ON i.i_item_id = ir.i_item_id
    GROUP BY s.s_store_id, s.s_store_name, i.i_category_id, i.i_category_name
),
store_customers AS (
    SELECT DISTINCT ss.ss_store_id AS store_id, ss.ss_customer_id
    FROM store_sales ss
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
),
overlap_agg AS (
    SELECT
        sc.store_id,
        i.i_category_id,
        i.i_category_name,
        SUM(ws.ws_quantity) AS total_overlap_web_quantity,
        COUNT(DISTINCT ws.ws_customer_id) AS distinct_overlap_customers
    FROM store_customers sc
    JOIN customers c ON sc.ss_customer_id = c.c_customer_id
    JOIN web_sales ws ON ws.ws_customer_id = c.c_customer_id
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY sc.store_id, i.i_category_id, i.i_category_name
)
SELECT
    sa.s_store_name,
    sa.i_category_name,
    sa.total_store_quantity,
    COALESCE(oa.total_overlap_web_quantity, 0) AS total_overlap_web_quantity,
    sa.distinct_store_customers,
    COALESCE(oa.distinct_overlap_customers, 0) AS distinct_overlap_customers,
    sa.avg_item_price,
    sa.avg_item_rating,
    sa.total_review_count
FROM store_agg sa
LEFT JOIN overlap_agg oa
    ON sa.s_store_id = oa.store_id
   AND sa.i_category_id = oa.i_category_id
ORDER BY sa.s_store_name, sa.i_category_name
