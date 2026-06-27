WITH store_agg AS (
   SELECT ss.ss_store_id AS store_id,
          i.i_category_id AS category_id,
          i.i_category_name AS category_name,
          SUM(ss.ss_quantity) AS store_quantity,
          COUNT(DISTINCT ss.ss_customer_id) AS distinct_customers
   FROM store_sales ss
   JOIN items i ON ss.ss_item_id = i.i_item_id
   GROUP BY ss.ss_store_id, i.i_category_id, i.i_category_name
),
web_agg AS (
   SELECT i.i_category_id AS category_id,
          i.i_category_name AS category_name,
          SUM(ws.ws_quantity) AS web_quantity
   FROM web_sales ws
   JOIN items i ON ws.ws_item_id = i.i_item_id
   GROUP BY i.i_category_id, i.i_category_name
),
rating_agg AS (
   SELECT i.i_category_id AS category_id,
          i.i_category_name AS category_name,
          AVG(pr.pr_rating) AS avg_rating
   FROM product_reviews pr
   JOIN items i ON pr.pr_item_id = i.i_item_id
   GROUP BY i.i_category_id, i.i_category_name
)
SELECT s.store_id,
       st.s_store_name,
       s.category_id,
       s.category_name,
       s.store_quantity,
       COALESCE(w.web_quantity, 0) AS web_quantity,
       s.distinct_customers,
       r.avg_rating
FROM store_agg s
JOIN stores st ON s.store_id = st.s_store_id
LEFT JOIN web_agg w ON s.category_id = w.category_id AND s.category_name = w.category_name
LEFT JOIN rating_agg r ON s.category_id = r.category_id AND s.category_name = r.category_name
ORDER BY s.store_quantity DESC
LIMIT 100
