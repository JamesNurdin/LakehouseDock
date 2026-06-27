WITH in_store_sales AS (
    SELECT
        ss_item_id,
        SUM(ss_quantity) AS total_store_quantity,
        COUNT(DISTINCT ss_customer_id) AS distinct_store_customers,
        COUNT(DISTINCT ss_transaction_id) AS store_transactions
    FROM store_sales
    GROUP BY ss_item_id
),
online_sales AS (
    SELECT
        ws_item_id,
        SUM(ws_quantity) AS total_online_quantity,
        COUNT(DISTINCT ws_customer_id) AS distinct_online_customers,
        COUNT(DISTINCT ws_transaction_id) AS online_transactions
    FROM web_sales
    GROUP BY ws_item_id
),
item_reviews AS (
    SELECT
        pr_item_id,
        AVG(pr_rating) AS avg_rating,
        COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT
    i.i_item_id,
    i.i_name,
    i.i_category_name,
    i.i_price,
    COALESCE(isales.total_store_quantity, 0) AS total_store_quantity,
    COALESCE(isales.distinct_store_customers, 0) AS distinct_store_customers,
    COALESCE(isales.store_transactions, 0) AS store_transactions,
    COALESCE(osales.total_online_quantity, 0) AS total_online_quantity,
    COALESCE(osales.distinct_online_customers, 0) AS distinct_online_customers,
    COALESCE(osales.online_transactions, 0) AS online_transactions,
    COALESCE(rev.avg_rating, NULL) AS avg_rating,
    COALESCE(rev.review_count, 0) AS review_count
FROM items i
LEFT JOIN in_store_sales isales ON isales.ss_item_id = i.i_item_id
LEFT JOIN online_sales osales ON osales.ws_item_id = i.i_item_id
LEFT JOIN item_reviews rev ON rev.pr_item_id = i.i_item_id
ORDER BY i.i_category_name, i.i_name
