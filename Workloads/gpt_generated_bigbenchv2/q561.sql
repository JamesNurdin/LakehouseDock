WITH combined_sales AS (
    SELECT ss_item_id AS item_id,
           ss_customer_id AS customer_id,
           ss_quantity AS quantity
    FROM store_sales
    UNION ALL
    SELECT ws_item_id AS item_id,
           ws_customer_id AS customer_id,
           ws_quantity AS quantity
    FROM web_sales
),
sales_agg AS (
    SELECT cs.item_id,
           SUM(cs.quantity) AS total_quantity,
           SUM(cs.quantity * i.i_price) AS total_revenue,
           COUNT(DISTINCT cs.customer_id) AS distinct_customers
    FROM combined_sales cs
    JOIN items i
      ON cs.item_id = i.i_item_id
    GROUP BY cs.item_id
),
sentiment_agg AS (
    SELECT pr.pr_item_id AS item_id,
           AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT i.i_item_id,
       i.i_name,
       i.i_category,
       sa.total_quantity,
       sa.total_revenue,
       sa.distinct_customers,
       sa2.avg_sentiment
FROM items i
LEFT JOIN sales_agg sa
  ON i.i_item_id = sa.item_id
LEFT JOIN sentiment_agg sa2
  ON i.i_item_id = sa2.item_id
WHERE sa.total_quantity IS NOT NULL
ORDER BY sa.total_revenue DESC
LIMIT 20
