/*
  Store‑level category performance with average product ratings.
  For each store and product category we compute:
    • Total quantity sold
    • Total revenue (quantity × price)
    • Number of distinct customers who bought from the store
    • Average rating of the category (based on product reviews)
    • Total number of reviews for the category
*/
WITH item_ratings AS (
    SELECT
        pr_item_id,
        AVG(pr_rating) AS avg_item_rating,
        COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
),
category_ratings AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        AVG(ir.avg_item_rating) AS avg_category_rating,
        SUM(ir.review_count) AS total_category_reviews
    FROM items i
    LEFT JOIN item_ratings ir
        ON i.i_item_id = ir.pr_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
store_sales_agg AS (
    SELECT
        ss.ss_store_id,
        i.i_category_id,
        i.i_category_name,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_revenue,
        COUNT(DISTINCT ss.ss_customer_id) AS distinct_customers
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_store_id, i.i_category_id, i.i_category_name
)
SELECT
    s.s_store_name,
    a.i_category_name,
    a.total_quantity,
    a.total_revenue,
    a.distinct_customers,
    COALESCE(cr.avg_category_rating, 0) AS avg_rating_of_category,
    COALESCE(cr.total_category_reviews, 0) AS total_reviews_of_category
FROM store_sales_agg a
JOIN stores s
    ON a.ss_store_id = s.s_store_id
LEFT JOIN category_ratings cr
    ON a.i_category_id = cr.i_category_id
    AND a.i_category_name = cr.i_category_name
ORDER BY s.s_store_name, a.i_category_name
