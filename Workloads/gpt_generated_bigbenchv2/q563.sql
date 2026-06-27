WITH sales_agg AS (
    SELECT i.i_category_id,
           i.i_category_name,
           sum(ws.ws_quantity) AS total_quantity,
           sum(ws.ws_quantity * i.i_price) AS total_revenue,
           count(DISTINCT ws.ws_item_id) AS distinct_items_sold
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
reviews_agg AS (
    SELECT i.i_category_id,
           i.i_category_name,
           avg(pr.pr_rating) AS avg_rating,
           count(*) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
)
SELECT s.i_category_id,
       s.i_category_name,
       s.total_quantity,
       s.total_revenue,
       s.total_revenue / nullif(s.total_quantity, 0) AS avg_selling_price,
       s.distinct_items_sold,
       r.avg_rating,
       r.review_count,
       rank() OVER (ORDER BY s.total_revenue DESC) AS revenue_rank
FROM sales_agg s
LEFT JOIN reviews_agg r
  ON s.i_category_id = r.i_category_id
  AND s.i_category_name = r.i_category_name
ORDER BY s.total_revenue DESC
LIMIT 10
