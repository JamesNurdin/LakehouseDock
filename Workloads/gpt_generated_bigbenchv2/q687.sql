WITH store_sales_agg AS (
    SELECT ss_item_id AS item_id,
           SUM(ss_quantity) AS store_quantity
    FROM store_sales
    GROUP BY ss_item_id
),
web_sales_agg AS (
    SELECT ws_item_id AS item_id,
           SUM(ws_quantity) AS web_quantity
    FROM web_sales
    GROUP BY ws_item_id
),
combined_sales AS (
    SELECT item_id,
           SUM(qty) AS total_quantity
    FROM (
        SELECT item_id, store_quantity AS qty FROM store_sales_agg
        UNION ALL
        SELECT item_id, web_quantity AS qty FROM web_sales_agg
    ) u
    GROUP BY item_id
),
review_agg AS (
    SELECT pr_item_id AS item_id,
           AVG(pr_sentiment) AS avg_sentiment
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT i.i_item_id,
       i.i_name,
       i.i_category,
       cs.total_quantity,
       cs.total_quantity * i.i_price AS total_revenue,
       r.avg_sentiment
FROM combined_sales cs
JOIN items i ON cs.item_id = i.i_item_id
LEFT JOIN review_agg r ON i.i_item_id = r.item_id
ORDER BY total_revenue DESC
LIMIT 10
