WITH store_sales_agg AS (
    SELECT ss_item_id,
           SUM(ss_quantity) AS store_quantity,
           COUNT(DISTINCT ss_transaction_id) AS store_transactions
    FROM store_sales
    GROUP BY ss_item_id
),
web_sales_agg AS (
    SELECT ws_item_id,
           SUM(ws_quantity) AS web_quantity,
           COUNT(DISTINCT ws_transaction_id) AS web_transactions
    FROM web_sales
    GROUP BY ws_item_id
),
reviews_agg AS (
    SELECT pr_item_id,
           AVG(pr_sentiment) AS avg_sentiment,
           COUNT(pr_review_id) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
),
item_sales AS (
    SELECT
        i.i_item_id,
        i.i_category,
        i.i_category_id,
        i.i_price,
        COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0) AS total_quantity,
        (COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0)) * i.i_price AS total_revenue,
        COALESCE(sa.store_transactions, 0) + COALESCE(wa.web_transactions, 0) AS total_transactions,
        ra.avg_sentiment,
        COALESCE(ra.review_count, 0) AS review_count
    FROM items i
    LEFT JOIN store_sales_agg sa ON sa.ss_item_id = i.i_item_id
    LEFT JOIN web_sales_agg wa ON wa.ws_item_id = i.i_item_id
    LEFT JOIN reviews_agg ra ON ra.pr_item_id = i.i_item_id
)
SELECT
    isales.i_category,
    isales.i_category_id,
    SUM(isales.total_quantity) AS category_quantity_sold,
    SUM(isales.total_revenue) AS category_revenue,
    SUM(isales.total_transactions) AS category_transactions,
    AVG(isales.avg_sentiment) AS category_avg_sentiment,
    SUM(isales.review_count) AS category_review_count
FROM item_sales isales
GROUP BY isales.i_category, isales.i_category_id
ORDER BY category_quantity_sold DESC
LIMIT 10
