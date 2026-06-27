/*
  Analytical query: per store and item category compute total quantity sold,
  total revenue, distinct items sold, average product rating and review count.
  Uses store_sales, items, stores, and product_reviews.
*/
WITH item_rating AS (
    SELECT
        pr.pr_item_id AS i_item_id,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(*) AS review_cnt
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
),
store_sales_detail AS (
    SELECT
        ss.ss_store_id AS s_store_id,
        i.i_category_id,
        i.i_category_name,
        ss.ss_quantity AS quantity,
        ss.ss_quantity * i.i_price AS revenue,
        i.i_item_id
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
),
store_category_agg AS (
    SELECT
        ssd.s_store_id,
        ssd.i_category_id,
        ssd.i_category_name,
        SUM(ssd.quantity) AS total_quantity,
        SUM(ssd.revenue) AS total_revenue,
        COUNT(DISTINCT ssd.i_item_id) AS distinct_items_sold
    FROM store_sales_detail ssd
    GROUP BY ssd.s_store_id, ssd.i_category_id, ssd.i_category_name
),
store_category_rating AS (
    SELECT
        ssd.s_store_id,
        ssd.i_category_id,
        AVG(ir.avg_rating) AS avg_category_rating,
        SUM(ir.review_cnt) AS total_reviews
    FROM store_sales_detail ssd
    LEFT JOIN item_rating ir ON ssd.i_item_id = ir.i_item_id
    GROUP BY ssd.s_store_id, ssd.i_category_id
)
SELECT
    s.s_store_name,
    ca.i_category_name,
    ca.total_quantity,
    ca.total_revenue,
    ca.distinct_items_sold,
    cr.avg_category_rating,
    cr.total_reviews
FROM store_category_agg ca
JOIN stores s ON ca.s_store_id = s.s_store_id
LEFT JOIN store_category_rating cr
    ON ca.s_store_id = cr.s_store_id
   AND ca.i_category_id = cr.i_category_id
ORDER BY ca.total_revenue DESC
LIMIT 20
