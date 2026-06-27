WITH item_ratings AS (
    SELECT i.i_item_id,
           AVG(pr.pr_rating) AS avg_rating,
           COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
store_sales_by_item AS (
    SELECT ss.ss_store_id,
           i.i_item_id,
           SUM(ss.ss_quantity) AS store_quantity,
           SUM(ss.ss_quantity * i.i_price) AS store_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_store_id, i.i_item_id
),
web_sales_by_item AS (
    SELECT i.i_item_id,
           SUM(ws.ws_quantity) AS web_quantity
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
store_aggregates AS (
    SELECT s.s_store_id,
           s.s_store_name,
           SUM(ssb.store_quantity) AS total_quantity,
           SUM(ssb.store_revenue) AS total_revenue,
           SUM(ssb.store_quantity * COALESCE(ir.avg_rating, 0)) / NULLIF(SUM(ssb.store_quantity), 0) AS weighted_avg_rating,
           SUM(COALESCE(ir.review_count, 0)) AS total_reviews,
           SUM(COALESCE(wb.web_quantity, 0)) AS total_web_quantity
    FROM store_sales_by_item ssb
    JOIN stores s ON ssb.ss_store_id = s.s_store_id
    LEFT JOIN item_ratings ir ON ssb.i_item_id = ir.i_item_id
    LEFT JOIN web_sales_by_item wb ON ssb.i_item_id = wb.i_item_id
    GROUP BY s.s_store_id, s.s_store_name
)
SELECT s_store_id,
       s_store_name,
       total_quantity,
       total_revenue,
       weighted_avg_rating,
       total_reviews,
       total_web_quantity
FROM store_aggregates
ORDER BY s_store_name
