WITH item_ratings AS (
    SELECT i.i_item_id,
           avg(pr.pr_rating) AS avg_rating,
           count(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
online_sales AS (
    SELECT i.i_item_id,
           sum(ws.ws_quantity) AS online_quantity
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_item_id
)
SELECT s.s_store_name,
       i.i_category_name,
       i.i_item_id,
       i.i_name,
       sum(ss.ss_quantity) AS store_quantity,
       sum(ss.ss_quantity * i.i_price) AS store_revenue,
       count(distinct ss.ss_customer_id) AS distinct_store_customers,
       coalesce(os.online_quantity, 0) AS online_quantity,
       coalesce(ir.avg_rating, 0) AS avg_rating,
       coalesce(ir.review_count, 0) AS review_count
FROM store_sales ss
JOIN customers c ON ss.ss_customer_id = c.c_customer_id
JOIN items i ON ss.ss_item_id = i.i_item_id
JOIN stores s ON ss.ss_store_id = s.s_store_id
LEFT JOIN item_ratings ir ON i.i_item_id = ir.i_item_id
LEFT JOIN online_sales os ON i.i_item_id = os.i_item_id
GROUP BY s.s_store_name,
         i.i_category_name,
         i.i_item_id,
         i.i_name,
         os.online_quantity,
         ir.avg_rating,
         ir.review_count
HAVING sum(ss.ss_quantity) > 0
ORDER BY s.s_store_name, i.i_category_name, store_quantity DESC
