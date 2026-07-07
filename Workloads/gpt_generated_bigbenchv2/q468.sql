WITH all_sales AS (
    SELECT ss.ss_item_id AS item_id,
           ss.ss_quantity AS quantity,
           i.i_price AS price
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    UNION ALL
    SELECT ws.ws_item_id AS item_id,
           ws.ws_quantity AS quantity,
           i.i_price AS price
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
),
sales_agg AS (
    SELECT item_id,
           SUM(quantity) AS total_quantity,
           SUM(quantity * price) AS total_revenue
    FROM all_sales
    GROUP BY item_id
),
customer_counts AS (
    SELECT item_id,
           COUNT(DISTINCT customer_id) AS distinct_customer_count
    FROM (
        SELECT ss.ss_customer_id AS customer_id, ss.ss_item_id AS item_id
        FROM store_sales ss
        UNION ALL
        SELECT ws.ws_customer_id AS customer_id, ws.ws_item_id AS item_id
        FROM web_sales ws
    ) AS combined
    GROUP BY item_id
),
sentiment_agg AS (
    SELECT i.i_item_id AS item_id,
           AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
)
SELECT i.i_item_id,
       i.i_name,
       i.i_category,
       i.i_price,
       COALESCE(s.total_quantity, 0) AS total_quantity,
       COALESCE(s.total_revenue, 0) AS total_revenue,
       sa.avg_sentiment,
       COALESCE(cc.distinct_customer_count, 0) AS distinct_customer_count
FROM items i
LEFT JOIN sales_agg s ON i.i_item_id = s.item_id
LEFT JOIN sentiment_agg sa ON i.i_item_id = sa.item_id
LEFT JOIN customer_counts cc ON i.i_item_id = cc.item_id
ORDER BY total_revenue DESC
LIMIT 10
