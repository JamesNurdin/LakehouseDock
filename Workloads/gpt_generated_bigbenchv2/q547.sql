WITH store_sales_agg AS (
   SELECT
      i.i_category_id,
      i.i_category,
      s.s_store_name,
      SUM(ss.ss_quantity) AS store_qty
   FROM store_sales ss
   INNER JOIN items i ON ss.ss_item_id = i.i_item_id
   INNER JOIN stores s ON ss.ss_store_id = s.s_store_id
   GROUP BY i.i_category_id, i.i_category, s.s_store_name
),
store_sales_ranked AS (
   SELECT
      i_category_id,
      i_category,
      s_store_name,
      store_qty,
      ROW_NUMBER() OVER (PARTITION BY i_category_id ORDER BY store_qty DESC) AS rn
   FROM store_sales_agg
),
top_store_per_category AS (
   SELECT
      i_category_id,
      i_category,
      s_store_name AS top_store_name,
      store_qty AS top_store_qty
   FROM store_sales_ranked
   WHERE rn = 1
),
web_sales_agg AS (
   SELECT
      i.i_category_id,
      i.i_category,
      SUM(ws.ws_quantity) AS web_qty
   FROM web_sales ws
   INNER JOIN items i ON ws.ws_item_id = i.i_item_id
   GROUP BY i.i_category_id, i.i_category
),
review_agg AS (
   SELECT
      i.i_category_id,
      i.i_category,
      AVG(pr.pr_sentiment) AS avg_sentiment,
      COUNT(pr.pr_review_id) AS review_count
   FROM product_reviews pr
   INNER JOIN items i ON pr.pr_item_id = i.i_item_id
   GROUP BY i.i_category_id, i.i_category
),
customer_agg AS (
   SELECT
      i.i_category_id,
      i.i_category,
      COUNT(DISTINCT c.c_customer_id) AS distinct_customer_count
   FROM (
      SELECT ss.ss_customer_id AS c_customer_id, ss.ss_item_id AS item_id
      FROM store_sales ss
      UNION ALL
      SELECT ws.ws_customer_id AS c_customer_id, ws.ws_item_id AS item_id
      FROM web_sales ws
   ) sc
   INNER JOIN customers c ON sc.c_customer_id = c.c_customer_id
   INNER JOIN items i ON sc.item_id = i.i_item_id
   GROUP BY i.i_category_id, i.i_category
)
SELECT
   ts.i_category_id,
   ts.i_category,
   ts.top_store_name,
   ts.top_store_qty,
   COALESCE(ws.web_qty, 0) AS total_web_quantity,
   COALESCE(sa.store_qty, 0) AS total_store_quantity,
   COALESCE(ws.web_qty, 0) + COALESCE(sa.store_qty, 0) AS total_quantity,
   COALESCE(rv.avg_sentiment, 0) AS avg_review_sentiment,
   COALESCE(rv.review_count, 0) AS review_count,
   COALESCE(ca.distinct_customer_count, 0) AS distinct_customer_count
FROM top_store_per_category ts
LEFT JOIN (
   SELECT i_category_id, SUM(store_qty) AS store_qty
   FROM store_sales_agg
   GROUP BY i_category_id
) sa ON ts.i_category_id = sa.i_category_id
LEFT JOIN web_sales_agg ws ON ts.i_category_id = ws.i_category_id
LEFT JOIN review_agg rv ON ts.i_category_id = rv.i_category_id
LEFT JOIN customer_agg ca ON ts.i_category_id = ca.i_category_id
ORDER BY total_quantity DESC
LIMIT 10
