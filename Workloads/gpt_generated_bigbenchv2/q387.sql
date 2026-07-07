WITH sales_agg AS (
    SELECT i.i_category,
           SUM(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category
    UNION ALL
    SELECT i.i_category,
           SUM(ws.ws_quantity) AS total_quantity
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category
),
sales_total AS (
    SELECT i_category,
           SUM(total_quantity) AS total_quantity_sold
    FROM sales_agg
    GROUP BY i_category
),
reviews_agg AS (
    SELECT i.i_category,
           AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category
)
SELECT s.i_category,
       s.total_quantity_sold,
       r.avg_sentiment
FROM sales_total s
LEFT JOIN reviews_agg r ON s.i_category = r.i_category
ORDER BY s.total_quantity_sold DESC
