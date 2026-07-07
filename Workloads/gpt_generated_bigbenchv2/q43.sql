WITH store_sales_agg AS (
    SELECT s.s_store_id,
           s.s_store_name,
           i.i_category_id,
           i.i_category,
           SUM(ss.ss_quantity) AS total_store_qty,
           SUM(ss.ss_quantity * i.i_price) AS total_store_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    GROUP BY s.s_store_id, s.s_store_name, i.i_category_id, i.i_category
),
web_sales_agg AS (
    SELECT i.i_category_id,
           i.i_category,
           SUM(ws.ws_quantity) AS total_web_qty,
           SUM(ws.ws_quantity * i.i_price) AS total_web_revenue
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
review_agg AS (
    SELECT i.i_category_id,
           i.i_category,
           AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
)
SELECT ss.s_store_name,
       ss.i_category_id,
       ss.i_category,
       ss.total_store_qty,
       ss.total_store_revenue,
       COALESCE(ws.total_web_qty, 0) AS total_web_qty,
       COALESCE(ws.total_web_revenue, 0) AS total_web_revenue,
       r.avg_sentiment
FROM store_sales_agg ss
LEFT JOIN web_sales_agg ws
  ON ss.i_category_id = ws.i_category_id
 AND ss.i_category = ws.i_category
LEFT JOIN review_agg r
  ON ss.i_category_id = r.i_category_id
 AND ss.i_category = r.i_category
ORDER BY ss.s_store_name, ss.i_category_id
