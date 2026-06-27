WITH store_sales_agg AS (
    SELECT
        ss.ss_item_id AS item_id,
        i.i_name AS i_name,
        i.i_category_id AS i_category_id,
        i.i_category_name AS i_category_name,
        ss.ss_customer_id AS customer_id,
        ss.ss_quantity AS quantity,
        ss.ss_store_id AS store_id,
        'store' AS channel
    FROM store_sales ss
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
),
web_sales_agg AS (
    SELECT
        ws.ws_item_id AS item_id,
        i.i_name AS i_name,
        i.i_category_id AS i_category_id,
        i.i_category_name AS i_category_name,
        ws.ws_customer_id AS customer_id,
        ws.ws_quantity AS quantity,
        NULL AS store_id,
        'web' AS channel
    FROM web_sales ws
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    JOIN items i ON ws.ws_item_id = i.i_item_id
),
combined_sales AS (
    SELECT
        item_id,
        i_name,
        i_category_id,
        i_category_name,
        customer_id,
        quantity,
        store_id,
        channel
    FROM store_sales_agg
    UNION ALL
    SELECT
        item_id,
        i_name,
        i_category_id,
        i_category_name,
        customer_id,
        quantity,
        store_id,
        channel
    FROM web_sales_agg
),
item_sales AS (
    SELECT
        cs.item_id,
        cs.i_name,
        cs.i_category_id,
        cs.i_category_name,
        SUM(cs.quantity) AS total_quantity,
        COUNT(DISTINCT cs.customer_id) AS distinct_customers
    FROM combined_sales cs
    GROUP BY cs.item_id, cs.i_name, cs.i_category_id, cs.i_category_name
),
item_ratings AS (
    SELECT
        pr.pr_item_id AS item_id,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(*) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT
    isales.i_category_name,
    isales.i_name AS item_name,
    isales.total_quantity,
    isales.distinct_customers,
    COALESCE(ir.avg_rating, 0) AS avg_rating,
    COALESCE(ir.review_count, 0) AS review_count,
    RANK() OVER (PARTITION BY isales.i_category_name ORDER BY isales.total_quantity DESC) AS category_rank
FROM item_sales isales
LEFT JOIN item_ratings ir ON isales.item_id = ir.item_id
WHERE isales.total_quantity > 0
ORDER BY isales.total_quantity DESC
LIMIT 10
