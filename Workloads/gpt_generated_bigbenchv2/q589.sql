WITH store_sales_agg AS (
    SELECT ss.ss_store_id AS store_id,
           SUM(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    GROUP BY ss.ss_store_id
),
store_sentiment_agg AS (
    SELECT ss.ss_store_id AS store_id,
           AVG(pr.pr_sentiment) AS avg_sentiment
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN product_reviews pr ON pr.pr_item_id = i.i_item_id
    GROUP BY ss.ss_store_id
)
SELECT st.s_store_name,
       s.total_quantity,
       r.avg_sentiment
FROM store_sales_agg s
JOIN store_sentiment_agg r ON s.store_id = r.store_id
JOIN stores st ON s.store_id = st.s_store_id
ORDER BY s.total_quantity DESC
