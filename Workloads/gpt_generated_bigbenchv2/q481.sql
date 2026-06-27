WITH unified_sales AS (
    SELECT
        ss.ss_item_id AS item_id,
        ss.ss_quantity AS quantity,
        ss.ss_store_id AS store_id,
        'store' AS channel
    FROM store_sales ss
    UNION ALL
    SELECT
        ws.ws_item_id AS item_id,
        ws.ws_quantity AS quantity,
        NULL AS store_id,
        'web' AS channel
    FROM web_sales ws
),

sales_by_item AS (
    SELECT
        us.item_id,
        us.store_id,
        us.channel,
        SUM(us.quantity) AS quantity
    FROM unified_sales us
    GROUP BY us.item_id, us.store_id, us.channel
),

reviews_by_item AS (
    SELECT
        pr.pr_item_id AS item_id,
        SUM(pr.pr_rating) AS sum_rating,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT
    COALESCE(st.s_store_name, 'Online') AS sales_location,
    i.i_category_id,
    i.i_category_name,
    SUM(CASE WHEN s.channel = 'store' THEN s.quantity ELSE 0 END) AS total_store_quantity,
    SUM(CASE WHEN s.channel = 'web'   THEN s.quantity ELSE 0 END) AS total_web_quantity,
    COUNT(DISTINCT i.i_item_id) AS distinct_items_sold,
    CASE
        WHEN SUM(COALESCE(r.review_count, 0)) = 0 THEN NULL
        ELSE SUM(COALESCE(r.sum_rating, 0)) / SUM(COALESCE(r.review_count, 0))
    END AS average_rating,
    SUM(COALESCE(r.review_count, 0)) AS total_review_count
FROM sales_by_item s
JOIN items i
    ON s.item_id = i.i_item_id
LEFT JOIN reviews_by_item r
    ON i.i_item_id = r.item_id
LEFT JOIN stores st
    ON s.store_id = st.s_store_id
GROUP BY
    COALESCE(st.s_store_name, 'Online'),
    i.i_category_id,
    i.i_category_name
ORDER BY (total_store_quantity + total_web_quantity) DESC
LIMIT 20
