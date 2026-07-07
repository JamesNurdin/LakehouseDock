WITH store_agg AS (
    SELECT i.i_item_id,
           i.i_category,
           SUM(ss.ss_quantity) AS store_quantity
    FROM items i
    JOIN store_sales ss ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_item_id, i.i_category
),
web_agg AS (
    SELECT i.i_item_id,
           i.i_category,
           SUM(ws.ws_quantity) AS web_quantity
    FROM items i
    JOIN web_sales ws ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_item_id, i.i_category
),
review_agg AS (
    SELECT i.i_item_id,
           i.i_category,
           COUNT(pr.pr_review_id) AS review_count,
           SUM(pr.pr_sentiment) AS sentiment_sum
    FROM items i
    JOIN product_reviews pr ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id, i.i_category
)
SELECT i.i_category,
       SUM(COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0)) AS total_quantity_sold,
       AVG(i.i_price) AS avg_price,
       SUM(COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0)) * AVG(i.i_price) AS total_sales_value,
       SUM(COALESCE(ra.review_count, 0)) AS total_reviews,
       CASE WHEN SUM(COALESCE(ra.review_count, 0)) = 0 THEN NULL
            ELSE SUM(COALESCE(ra.sentiment_sum, 0)) / SUM(COALESCE(ra.review_count, 0))
       END AS avg_review_sentiment
FROM items i
LEFT JOIN store_agg sa ON sa.i_item_id = i.i_item_id
LEFT JOIN web_agg wa ON wa.i_item_id = i.i_item_id
LEFT JOIN review_agg ra ON ra.i_item_id = i.i_item_id
GROUP BY i.i_category
ORDER BY total_quantity_sold DESC
LIMIT 10
