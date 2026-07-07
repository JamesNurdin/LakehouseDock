WITH sales_detail AS (
    SELECT ss.ss_item_id AS item_id,
           ss.ss_quantity AS quantity,
           ss.ss_customer_id AS customer_id
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_item_id AS item_id,
           ws.ws_quantity AS quantity,
           ws.ws_customer_id AS customer_id
    FROM web_sales ws
),
sales_agg AS (
    SELECT item_id,
           SUM(quantity) AS total_quantity
    FROM sales_detail
    GROUP BY item_id
),
category_customers AS (
    SELECT i.i_category AS category,
           COUNT(DISTINCT sd.customer_id) AS distinct_customers
    FROM sales_detail sd
    JOIN items i ON sd.item_id = i.i_item_id
    GROUP BY i.i_category
),
reviews_agg AS (
    SELECT pr.pr_item_id AS item_id,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT i.i_category,
       SUM(COALESCE(s.total_quantity, 0)) AS total_quantity_sold,
       AVG(i.i_price) AS avg_item_price,
       COALESCE(SUM(r.review_count), 0) AS total_review_count,
       AVG(r.avg_sentiment) AS avg_review_sentiment,
       cc.distinct_customers
FROM items i
LEFT JOIN sales_agg s ON i.i_item_id = s.item_id
LEFT JOIN reviews_agg r ON i.i_item_id = r.item_id
LEFT JOIN category_customers cc ON i.i_category = cc.category
GROUP BY i.i_category, cc.distinct_customers
ORDER BY total_quantity_sold DESC
LIMIT 10
