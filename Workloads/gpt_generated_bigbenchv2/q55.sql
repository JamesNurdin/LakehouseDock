WITH
    -- Sales details with item price
    item_sales AS (
        SELECT
            ss.ss_store_id,
            ss.ss_item_id,
            ss.ss_quantity,
            i.i_price
        FROM store_sales ss
        JOIN items i ON ss.ss_item_id = i.i_item_id
    ),
    -- Average rating per item from product reviews
    item_rating AS (
        SELECT
            pr.pr_item_id,
            AVG(pr.pr_rating) AS avg_rating
        FROM product_reviews pr
        GROUP BY pr.pr_item_id
    ),
    -- Revenue and quantity metrics per store
    store_revenue AS (
        SELECT
            isales.ss_store_id,
            SUM(isales.ss_quantity * isales.i_price) AS total_revenue,
            COUNT(DISTINCT isales.ss_item_id) AS distinct_items_sold,
            SUM(isales.ss_quantity) AS total_quantity_sold
        FROM item_sales isales
        GROUP BY isales.ss_store_id
    ),
    -- Average item rating for items sold in each store
    store_avg_rating AS (
        SELECT
            ss.ss_store_id,
            AVG(ir.avg_rating) AS avg_item_rating
        FROM store_sales ss
        JOIN items i ON ss.ss_item_id = i.i_item_id
        JOIN item_rating ir ON i.i_item_id = ir.pr_item_id
        GROUP BY ss.ss_store_id
    )
SELECT
    s.s_store_name,
    sr.total_revenue,
    sr.total_quantity_sold,
    sr.distinct_items_sold,
    sar.avg_item_rating
FROM store_revenue sr
JOIN store_avg_rating sar ON sr.ss_store_id = sar.ss_store_id
JOIN stores s ON sr.ss_store_id = s.s_store_id
ORDER BY sr.total_revenue DESC
LIMIT 10
