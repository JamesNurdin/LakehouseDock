WITH store_total_sales AS (
    SELECT
        ss_item_id,
        SUM(ss_quantity) AS total_store_quantity
    FROM store_sales
    GROUP BY ss_item_id
),
store_item_sales AS (
    SELECT
        ss_item_id,
        ss_store_id,
        SUM(ss_quantity) AS store_quantity
    FROM store_sales
    GROUP BY ss_item_id, ss_store_id
),
store_top AS (
    SELECT
        si.ss_item_id,
        s.s_store_name,
        ROW_NUMBER() OVER (PARTITION BY si.ss_item_id ORDER BY si.store_quantity DESC) AS rn
    FROM store_item_sales si
    JOIN stores s
        ON s.s_store_id = si.ss_store_id
),
top_store_per_item AS (
    SELECT
        ss_item_id,
        s_store_name
    FROM store_top
    WHERE rn = 1
),
web_total_sales AS (
    SELECT
        ws_item_id,
        SUM(ws_quantity) AS total_web_quantity
    FROM web_sales
    GROUP BY ws_item_id
),
review_agg AS (
    SELECT
        pr_item_id,
        COUNT(*) AS review_count,
        AVG(pr_rating) AS avg_rating
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT
    i.i_item_id,
    i.i_name,
    i.i_category_id,
    i.i_category_name,
    i.i_price,
    COALESCE(st.total_store_quantity, 0) + COALESCE(wt.total_web_quantity, 0) AS total_quantity_sold,
    COALESCE(rt.review_count, 0) AS total_review_count,
    rt.avg_rating,
    ts.s_store_name AS top_store_name
FROM items i
LEFT JOIN store_total_sales st
    ON st.ss_item_id = i.i_item_id
LEFT JOIN web_total_sales wt
    ON wt.ws_item_id = i.i_item_id
LEFT JOIN review_agg rt
    ON rt.pr_item_id = i.i_item_id
LEFT JOIN top_store_per_item ts
    ON ts.ss_item_id = i.i_item_id
WHERE i.i_price > 20.00
ORDER BY total_quantity_sold DESC
LIMIT 100
