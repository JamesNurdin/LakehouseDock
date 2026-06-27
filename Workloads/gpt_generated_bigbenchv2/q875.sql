WITH store_sales_item AS (
    SELECT
        ss.ss_store_id,
        ss.ss_item_id,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_store_id, ss.ss_item_id
),
reviews_item AS (
    SELECT
        pr.pr_item_id,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
),
stores_info AS (
    SELECT s.s_store_id, s.s_store_name FROM stores s
),
items_info AS (
    SELECT i.i_item_id, i.i_category_name FROM items i
)
SELECT
    si.s_store_name,
    ii.i_category_name,
    SUM(COALESCE(ssi.store_quantity, 0)) AS total_quantity_sold,
    SUM(COALESCE(ssi.store_revenue, 0)) AS total_revenue,
    AVG(ri.avg_rating) AS avg_rating,
    SUM(ri.review_count) AS total_reviews
FROM store_sales_item ssi
JOIN stores_info si ON si.s_store_id = ssi.ss_store_id
JOIN items_info ii ON ii.i_item_id = ssi.ss_item_id
LEFT JOIN reviews_item ri ON ri.pr_item_id = ssi.ss_item_id
GROUP BY si.s_store_name, ii.i_category_name
ORDER BY total_revenue DESC
LIMIT 10
