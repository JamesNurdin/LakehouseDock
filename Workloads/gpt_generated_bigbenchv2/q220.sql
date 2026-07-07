WITH store_sales_agg AS (
    SELECT ss.ss_store_id AS store_id,
           SUM(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    GROUP BY ss.ss_store_id
),
store_reviews AS (
    SELECT DISTINCT pr.pr_review_id,
           s.s_store_id AS store_id,
           pr.pr_sentiment AS sentiment
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    JOIN store_sales ss ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
),
store_reviews_agg AS (
    SELECT store_id,
           AVG(sentiment) AS avg_sentiment
    FROM store_reviews
    GROUP BY store_id
)
SELECT s.s_store_name,
       ss_agg.total_quantity,
       sr_agg.avg_sentiment
FROM stores s
LEFT JOIN store_sales_agg ss_agg
    ON s.s_store_id = ss_agg.store_id
LEFT JOIN store_reviews_agg sr_agg
    ON s.s_store_id = sr_agg.store_id
ORDER BY ss_agg.total_quantity DESC
LIMIT 10
