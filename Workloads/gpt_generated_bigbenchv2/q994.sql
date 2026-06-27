/*
  Analytical query: Top 10 stores by revenue, broken down by item category.
  For each store‑category pair the query returns:
    • total quantity sold
    • total revenue (quantity × price)
    • weighted average rating of the items sold (rating weighted by quantity)
    • total number of reviews for the items sold
*/
WITH item_ratings AS (
    SELECT
        i.i_item_id,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(pr.pr_review_id) AS review_cnt
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
store_item_sales AS (
    SELECT
        s.s_store_name,
        i.i_category_name,
        i.i_item_id,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    GROUP BY s.s_store_name, i.i_category_name, i.i_item_id
)
SELECT
    si.s_store_name,
    si.i_category_name,
    SUM(si.total_quantity) AS total_quantity,
    SUM(si.total_revenue) AS total_revenue,
    CASE
        WHEN SUM(si.total_quantity) > 0 THEN
            SUM(si.total_quantity * COALESCE(r.avg_rating, 0)) / SUM(si.total_quantity)
        ELSE 0
    END AS weighted_avg_rating,
    SUM(COALESCE(r.review_cnt, 0)) AS total_review_count
FROM store_item_sales si
LEFT JOIN item_ratings r ON si.i_item_id = r.i_item_id
GROUP BY si.s_store_name, si.i_category_name
ORDER BY total_revenue DESC
LIMIT 10
