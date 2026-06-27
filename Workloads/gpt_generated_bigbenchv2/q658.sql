WITH unified_sales AS (
    SELECT
        ss.ss_store_id AS store_id,
        ss.ss_item_id AS item_id,
        ss.ss_quantity AS quantity,
        ss.ss_customer_id AS customer_id
    FROM store_sales ss
    UNION ALL
    SELECT
        NULL AS store_id,
        ws.ws_item_id AS item_id,
        ws.ws_quantity AS quantity,
        ws.ws_customer_id AS customer_id
    FROM web_sales ws
),
sales_agg AS (
    SELECT
        COALESCE(store_id, -1) AS store_id,
        item_id,
        SUM(quantity) AS total_quantity,
        SUM(CASE WHEN store_id IS NOT NULL THEN quantity ELSE 0 END) AS store_quantity,
        SUM(CASE WHEN store_id IS NULL THEN quantity ELSE 0 END) AS web_quantity,
        COUNT(DISTINCT customer_id) AS total_customers
    FROM unified_sales
    GROUP BY COALESCE(store_id, -1), item_id
),
item_info AS (
    SELECT
        i.i_item_id,
        i.i_name,
        i.i_category_name,
        i.i_price
    FROM items i
),
rating_info AS (
    SELECT
        pr.pr_item_id,
        COUNT(*) AS review_count,
        AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
),
store_info AS (
    SELECT
        s.s_store_id,
        s.s_store_name
    FROM stores s
)
SELECT
    COALESCE(si.s_store_name, 'Online') AS store_name,
    ii.i_name AS item_name,
    ii.i_category_name,
    sa.total_quantity,
    sa.store_quantity,
    sa.web_quantity,
    sa.total_customers,
    ri.review_count,
    ROUND(ri.avg_rating, 2) AS avg_rating,
    ROUND(sa.total_quantity * ii.i_price, 2) AS total_sales_amount
FROM sales_agg sa
JOIN item_info ii ON sa.item_id = ii.i_item_id
LEFT JOIN rating_info ri ON sa.item_id = ri.pr_item_id
LEFT JOIN store_info si ON sa.store_id = si.s_store_id
WHERE sa.total_quantity > 0
ORDER BY total_sales_amount DESC
LIMIT 20
