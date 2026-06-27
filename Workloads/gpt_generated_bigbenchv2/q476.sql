WITH store_item_sales AS (
    SELECT
        ss.ss_store_id,
        ss.ss_item_id,
        SUM(ss.ss_quantity) AS store_qty
    FROM store_sales ss
    GROUP BY ss.ss_store_id, ss.ss_item_id
),
item_reviews AS (
    SELECT
        pr.pr_item_id,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(pr.pr_review_id) AS review_cnt
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT
    s.s_store_name,
    i.i_category_name,
    COUNT(DISTINCT si.ss_item_id) AS distinct_items_sold,
    SUM(si.store_qty) AS total_store_quantity,
    AVG(COALESCE(ir.avg_rating, 0)) AS avg_item_rating,
    SUM(COALESCE(ir.review_cnt, 0)) AS total_review_count,
    AVG(i.i_price) AS avg_item_price,
    AVG(i.i_comp_price) AS avg_competitor_price,
    AVG(i.i_price - i.i_comp_price) AS avg_price_difference
FROM store_item_sales si
JOIN stores s
    ON si.ss_store_id = s.s_store_id
JOIN items i
    ON si.ss_item_id = i.i_item_id
LEFT JOIN item_reviews ir
    ON i.i_item_id = ir.pr_item_id
GROUP BY s.s_store_name, i.i_category_name
ORDER BY total_store_quantity DESC
LIMIT 10
