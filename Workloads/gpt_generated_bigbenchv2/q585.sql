WITH store_revenue AS (
    SELECT
        ss.ss_store_id,
        i.i_category_id,
        i.i_category_name,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue,
        SUM(ss.ss_quantity) AS total_quantity_sold,
        COUNT(DISTINCT ss.ss_item_id) AS distinct_items_sold
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_store_id, i.i_category_id, i.i_category_name
),
category_rating AS (
    SELECT
        i.i_category_id,
        AVG(pr.pr_rating) AS avg_category_rating,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i
        ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id
),
store_info AS (
    SELECT
        s_store_id,
        s_store_name
    FROM stores
),
ranked_store_category AS (
    SELECT
        sr.*,
        ROW_NUMBER() OVER (PARTITION BY sr.ss_store_id ORDER BY sr.store_revenue DESC) AS category_rank
    FROM store_revenue sr
)
SELECT
    s.s_store_name,
    rsc.i_category_name,
    rsc.store_revenue,
    rsc.total_quantity_sold,
    rsc.distinct_items_sold,
    cr.avg_category_rating,
    cr.review_count
FROM ranked_store_category rsc
JOIN store_info s
    ON s.s_store_id = rsc.ss_store_id
LEFT JOIN category_rating cr
    ON cr.i_category_id = rsc.i_category_id
WHERE rsc.category_rank <= 5
ORDER BY s.s_store_name, rsc.store_revenue DESC
