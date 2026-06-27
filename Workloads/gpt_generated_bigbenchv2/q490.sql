WITH category_rating_agg AS (
    SELECT
        i.i_category_name,
        AVG(pr.pr_rating) AS avg_category_rating,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_name
),
store_category_sales AS (
    SELECT
        s.s_store_name,
        i.i_category_name,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    GROUP BY s.s_store_name, i.i_category_name
),
store_category_with_rating AS (
    SELECT
        scs.s_store_name,
        scs.i_category_name,
        scs.total_quantity,
        scs.total_revenue,
        cra.avg_category_rating,
        cra.review_count
    FROM store_category_sales scs
    LEFT JOIN category_rating_agg cra
        ON scs.i_category_name = cra.i_category_name
),
ranked_store_category AS (
    SELECT
        s_store_name,
        i_category_name,
        total_quantity,
        total_revenue,
        avg_category_rating,
        review_count,
        ROW_NUMBER() OVER (PARTITION BY s_store_name ORDER BY total_revenue DESC) AS rnk
    FROM store_category_with_rating
)
SELECT
    s_store_name AS store_name,
    i_category_name AS category_name,
    total_quantity,
    total_revenue,
    avg_category_rating,
    review_count
FROM ranked_store_category
WHERE rnk <= 3
ORDER BY s_store_name, rnk
