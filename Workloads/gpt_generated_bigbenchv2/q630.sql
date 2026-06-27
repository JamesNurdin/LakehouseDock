WITH item_sales AS (
    SELECT
        i.i_item_id,
        i.i_name,
        i.i_category_id,
        i.i_category_name,
        i.i_price,
        i.i_comp_price,
        SUM(ss.ss_quantity) AS store_quantity,
        COUNT(DISTINCT ss.ss_transaction_id) AS store_transactions
    FROM items i
    LEFT JOIN store_sales ss ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_item_id, i.i_name, i.i_category_id, i.i_category_name, i.i_price, i.i_comp_price
),
web_item_sales AS (
    SELECT
        i.i_item_id,
        SUM(ws.ws_quantity) AS web_quantity,
        COUNT(DISTINCT ws.ws_transaction_id) AS web_transactions
    FROM items i
    LEFT JOIN web_sales ws ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
item_reviews AS (
    SELECT
        i.i_item_id,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(pr.pr_review_id) AS review_count
    FROM items i
    LEFT JOIN product_reviews pr ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
)
SELECT
    i_sales.i_category_name,
    i_sales.i_category_id,
    i_sales.i_item_id,
    i_sales.i_name,
    i_sales.i_price,
    i_sales.i_comp_price,
    (i_sales.i_price - i_sales.i_comp_price) AS price_diff,
    COALESCE(i_sales.store_quantity, 0) + COALESCE(w_sales.web_quantity, 0) AS total_quantity_sold,
    COALESCE(i_sales.store_quantity, 0) * i_sales.i_price AS store_revenue,
    COALESCE(w_sales.web_quantity, 0) * i_sales.i_price AS web_revenue,
    (COALESCE(i_sales.store_quantity, 0) + COALESCE(w_sales.web_quantity, 0)) * i_sales.i_price AS total_revenue,
    i_rev.avg_rating,
    i_rev.review_count
FROM item_sales i_sales
LEFT JOIN web_item_sales w_sales ON w_sales.i_item_id = i_sales.i_item_id
LEFT JOIN item_reviews i_rev ON i_rev.i_item_id = i_sales.i_item_id
ORDER BY total_revenue DESC
LIMIT 100
