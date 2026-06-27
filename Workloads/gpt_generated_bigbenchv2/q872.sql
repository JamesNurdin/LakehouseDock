WITH store_sales_agg AS (
    SELECT
        ss.ss_item_id AS item_id,
        ss.ss_store_id AS store_id,
        st.s_store_name AS store_name,
        ss.ss_quantity AS quantity,
        ss.ss_quantity * i.i_price AS revenue,
        'store' AS channel
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores st ON ss.ss_store_id = st.s_store_id
),
web_sales_agg AS (
    SELECT
        ws.ws_item_id AS item_id,
        NULL AS store_id,
        'Online' AS store_name,
        ws.ws_quantity AS quantity,
        ws.ws_quantity * i.i_price AS revenue,
        'web' AS channel
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
),
sales AS (
    SELECT
        item_id,
        store_id,
        store_name,
        quantity,
        revenue,
        channel
    FROM store_sales_agg
    UNION ALL
    SELECT
        item_id,
        store_id,
        store_name,
        quantity,
        revenue,
        channel
    FROM web_sales_agg
),
item_ratings AS (
    SELECT
        pr.pr_item_id AS item_id,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(*) AS rating_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT
    i.i_item_id,
    i.i_name,
    i.i_category_name,
    s.store_name,
    s.channel,
    SUM(s.quantity) AS total_quantity,
    SUM(s.revenue) AS total_revenue,
    r.avg_rating,
    r.rating_count
FROM sales s
JOIN items i ON s.item_id = i.i_item_id
LEFT JOIN item_ratings r ON i.i_item_id = r.item_id
GROUP BY
    i.i_item_id,
    i.i_name,
    i.i_category_name,
    s.store_name,
    s.channel,
    r.avg_rating,
    r.rating_count
ORDER BY total_revenue DESC
LIMIT 30
