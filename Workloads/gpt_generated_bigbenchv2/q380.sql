WITH store_sales_agg AS (
   SELECT i.i_category,
          i.i_category_id,
          SUM(ss.ss_quantity) AS store_quantity,
          COUNT(DISTINCT ss.ss_customer_id) AS store_customer_count
   FROM store_sales ss
   JOIN items i ON ss.ss_item_id = i.i_item_id
   GROUP BY i.i_category, i.i_category_id
),
web_sales_agg AS (
   SELECT i.i_category,
          i.i_category_id,
          SUM(ws.ws_quantity) AS web_quantity,
          COUNT(DISTINCT ws.ws_customer_id) AS web_customer_count
   FROM web_sales ws
   JOIN items i ON ws.ws_item_id = i.i_item_id
   GROUP BY i.i_category, i.i_category_id
),
sales_agg AS (
   SELECT COALESCE(ssa.i_category, wsa.i_category) AS i_category,
          COALESCE(ssa.i_category_id, wsa.i_category_id) AS i_category_id,
          COALESCE(ssa.store_quantity, 0) AS store_quantity,
          COALESCE(wsa.web_quantity, 0) AS web_quantity,
          COALESCE(ssa.store_customer_count, 0) AS store_customer_count,
          COALESCE(wsa.web_customer_count, 0) AS web_customer_count
   FROM store_sales_agg ssa
   FULL OUTER JOIN web_sales_agg wsa
     ON ssa.i_category = wsa.i_category
    AND ssa.i_category_id = wsa.i_category_id
),
review_agg AS (
   SELECT i.i_category,
          i.i_category_id,
          AVG(pr.pr_sentiment) AS avg_sentiment,
          COUNT(pr.pr_review_id) AS review_count
   FROM product_reviews pr
   JOIN items i ON pr.pr_item_id = i.i_item_id
   GROUP BY i.i_category, i.i_category_id
)
SELECT COALESCE(ra.i_category, sa.i_category) AS category,
       COALESCE(ra.i_category_id, sa.i_category_id) AS category_id,
       ra.avg_sentiment,
       ra.review_count,
       sa.store_quantity,
       sa.web_quantity,
       (sa.store_quantity + sa.web_quantity) AS total_quantity,
       (sa.store_customer_count + sa.web_customer_count) AS total_customer_count
FROM review_agg ra
FULL OUTER JOIN sales_agg sa
   ON ra.i_category = sa.i_category
  AND ra.i_category_id = sa.i_category_id
ORDER BY category
