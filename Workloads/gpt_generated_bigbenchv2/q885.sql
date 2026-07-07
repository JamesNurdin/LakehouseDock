WITH sales_agg AS (
    SELECT i.i_item_id,
           i.i_category,
           SUM(ws.ws_quantity * i.i_price) AS total_revenue,
           SUM(ws.ws_quantity) AS total_units_sold
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_item_id, i.i_category
),
review_agg AS (
    SELECT pr.pr_item_id,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT s.i_category,
       SUM(s.total_revenue) AS category_revenue,
       SUM(s.total_units_sold) AS category_units_sold,
       AVG(r.avg_sentiment) AS category_avg_sentiment,
       SUM(r.review_count) AS category_review_count
FROM sales_agg s
LEFT JOIN review_agg r ON s.i_item_id = r.pr_item_id
GROUP BY s.i_category
ORDER BY category_revenue DESC
LIMIT 10
