WITH store_sales_agg AS (
    SELECT i.i_item_id,
           SUM(ss.ss_quantity) AS store_quantity,
           COUNT(DISTINCT ss.ss_transaction_id) AS store_transactions
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
web_sales_agg AS (
    SELECT i.i_item_id,
           SUM(ws.ws_quantity) AS web_quantity,
           COUNT(DISTINCT ws.ws_transaction_id) AS web_transactions
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
reviews_agg AS (
    SELECT i.i_item_id,
           COUNT(pr.pr_review_id) AS review_count,
           AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
)
SELECT i.i_category,
       i.i_category_id,
       i.i_name,
       i.i_price,
       COALESCE(ssa.store_quantity, 0) + COALESCE(wsa.web_quantity, 0) AS total_quantity_sold,
       COALESCE(ssa.store_transactions, 0) + COALESCE(wsa.web_transactions, 0) AS total_transactions,
       COALESCE(rsa.review_count, 0) AS review_count,
       rsa.avg_sentiment
FROM items i
LEFT JOIN store_sales_agg ssa ON i.i_item_id = ssa.i_item_id
LEFT JOIN web_sales_agg wsa ON i.i_item_id = wsa.i_item_id
LEFT JOIN reviews_agg rsa ON i.i_item_id = rsa.i_item_id
ORDER BY total_quantity_sold DESC
LIMIT 20
