WITH store_sales_agg AS (
    SELECT i.i_category_id,
           i.i_category_name,
           SUM(ss.ss_quantity) AS store_quantity,
           SUM(ss.ss_quantity * i.i_price) AS store_revenue,
           COUNT(DISTINCT ss.ss_customer_id) AS store_customers
    FROM store_sales ss
    JOIN items i
      ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
web_sales_agg AS (
    SELECT i.i_category_id,
           i.i_category_name,
           SUM(ws.ws_quantity) AS web_quantity,
           SUM(ws.ws_quantity * i.i_price) AS web_revenue,
           COUNT(DISTINCT ws.ws_customer_id) AS web_customers
    FROM web_sales ws
    JOIN items i
      ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
reviews_agg AS (
    SELECT i.i_category_id,
           i.i_category_name,
           AVG(pr.pr_rating) AS avg_rating,
           COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i
      ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
)
SELECT COALESCE(ss.i_category_id, wa.i_category_id, ra.i_category_id) AS i_category_id,
       COALESCE(ss.i_category_name, wa.i_category_name, ra.i_category_name) AS i_category_name,
       COALESCE(ss.store_quantity, 0) + COALESCE(wa.web_quantity, 0) AS total_quantity,
       COALESCE(ss.store_revenue, 0) + COALESCE(wa.web_revenue, 0) AS total_revenue,
       COALESCE(ss.store_customers, 0) + COALESCE(wa.web_customers, 0) AS total_customers,
       ra.avg_rating,
       ra.review_count
FROM store_sales_agg ss
FULL OUTER JOIN web_sales_agg wa
  ON ss.i_category_id = wa.i_category_id
FULL OUTER JOIN reviews_agg ra
  ON COALESCE(ss.i_category_id, wa.i_category_id) = ra.i_category_id
ORDER BY total_revenue DESC
LIMIT 10
