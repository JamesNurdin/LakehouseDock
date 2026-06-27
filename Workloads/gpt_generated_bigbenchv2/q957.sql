WITH
    store_sales_with_price AS (
        SELECT
            ss.ss_store_id,
            i.i_item_id,
            i.i_category_name,
            ss.ss_quantity,
            i.i_price
        FROM store_sales ss
        JOIN items i ON ss.ss_item_id = i.i_item_id
    ),
    store_revenue AS (
        SELECT
            sswp.ss_store_id,
            sswp.i_category_name,
            SUM(sswp.ss_quantity) AS total_quantity,
            SUM(sswp.ss_quantity * sswp.i_price) AS total_revenue
        FROM store_sales_with_price sswp
        GROUP BY sswp.ss_store_id, sswp.i_category_name
    ),
    category_ratings AS (
        SELECT
            i.i_category_name,
            AVG(pr.pr_rating) AS avg_rating,
            COUNT(*) AS rating_count
        FROM product_reviews pr
        JOIN items i ON pr.pr_item_id = i.i_item_id
        GROUP BY i.i_category_name
    )
SELECT
    s.s_store_id,
    s.s_store_name,
    sr.i_category_name,
    sr.total_quantity,
    sr.total_revenue,
    cr.avg_rating,
    cr.rating_count
FROM stores s
JOIN store_revenue sr ON s.s_store_id = sr.ss_store_id
LEFT JOIN category_ratings cr ON sr.i_category_name = cr.i_category_name
ORDER BY sr.total_revenue DESC
LIMIT 20
