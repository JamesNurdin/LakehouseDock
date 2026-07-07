SELECT
   i.i_category,
   i.i_category_id,
   SUM(COALESCE(offline_sales.offline_qty, 0) + COALESCE(online_sales.online_qty, 0)) AS total_quantity_sold,
   SUM(COALESCE(offline_sales.offline_customer_cnt, 0) + COALESCE(online_sales.online_customer_cnt, 0)) AS total_customer_count,
   CASE WHEN SUM(COALESCE(review_stats.review_cnt, 0)) = 0 THEN NULL
        ELSE SUM(COALESCE(review_stats.avg_sentiment * review_stats.review_cnt, 0)) / SUM(COALESCE(review_stats.review_cnt, 0))
   END AS avg_review_sentiment,
   SUM(COALESCE(review_stats.review_cnt, 0)) AS total_review_count
FROM items i
LEFT JOIN (
   SELECT ss_item_id,
          SUM(ss_quantity) AS offline_qty,
          COUNT(DISTINCT ss_customer_id) AS offline_customer_cnt
   FROM store_sales
   GROUP BY ss_item_id
) offline_sales
   ON offline_sales.ss_item_id = i.i_item_id
LEFT JOIN (
   SELECT ws_item_id,
          SUM(ws_quantity) AS online_qty,
          COUNT(DISTINCT ws_customer_id) AS online_customer_cnt
   FROM web_sales
   GROUP BY ws_item_id
) online_sales
   ON online_sales.ws_item_id = i.i_item_id
LEFT JOIN (
   SELECT pr_item_id,
          AVG(pr_sentiment) AS avg_sentiment,
          COUNT(*) AS review_cnt
   FROM product_reviews
   GROUP BY pr_item_id
) review_stats
   ON review_stats.pr_item_id = i.i_item_id
GROUP BY i.i_category, i.i_category_id
ORDER BY total_quantity_sold DESC
LIMIT 10
