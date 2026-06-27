WITH
store_agg AS (
    SELECT ss.ss_item_id AS item_id,
           SUM(ss.ss_quantity) AS store_quantity,
           SUM(ss.ss_quantity * i.i_price) AS store_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_item_id
),
web_agg AS (
    SELECT ws.ws_item_id AS item_id,
           SUM(ws.ws_quantity) AS web_quantity,
           SUM(ws.ws_quantity * i.i_price) AS web_revenue
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY ws.ws_item_id
),
item_reviews AS (
    SELECT pr.pr_item_id AS item_id,
           AVG(pr.pr_rating) AS avg_rating,
           COUNT(*) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
),
item_sales AS (
    SELECT i.i_item_id,
           i.i_name,
           i.i_category_id,
           i.i_category_name,
           COALESCE(sa.store_quantity, 0) AS store_quantity,
           COALESCE(sa.store_revenue, 0) AS store_revenue,
           COALESCE(wa.web_quantity, 0) AS web_quantity,
           COALESCE(wa.web_revenue, 0) AS web_revenue,
           ir.avg_rating,
           ir.review_count
    FROM items i
    LEFT JOIN store_agg sa ON sa.item_id = i.i_item_id
    LEFT JOIN web_agg wa ON wa.item_id = i.i_item_id
    LEFT JOIN item_reviews ir ON ir.item_id = i.i_item_id
),
category_sales AS (
    SELECT i_category_id,
           i_category_name,
           SUM(store_quantity + web_quantity) AS total_quantity_sold,
           SUM(store_revenue + web_revenue) AS total_revenue,
           AVG(avg_rating) AS avg_item_rating,
           SUM(COALESCE(review_count, 0)) AS total_reviews,
           COUNT(DISTINCT i_item_id) AS distinct_items_sold
    FROM item_sales
    GROUP BY i_category_id, i_category_name
),
customer_purchases AS (
    SELECT i.i_category_id,
           i.i_category_name,
           c.c_customer_id
    FROM store_sales ss
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
    UNION
    SELECT i.i_category_id,
           i.i_category_name,
           c.c_customer_id
    FROM web_sales ws
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    JOIN items i ON ws.ws_item_id = i.i_item_id
),
category_customers AS (
    SELECT i_category_id,
           i_category_name,
           COUNT(DISTINCT c_customer_id) AS distinct_customer_count
    FROM customer_purchases
    GROUP BY i_category_id, i_category_name
)
SELECT cs.i_category_id,
       cs.i_category_name,
       cs.total_quantity_sold,
       cs.total_revenue,
       cs.avg_item_rating,
       cs.total_reviews,
       cs.distinct_items_sold,
       cc.distinct_customer_count
FROM category_sales cs
JOIN category_customers cc
  ON cs.i_category_id = cc.i_category_id
 AND cs.i_category_name = cc.i_category_name
ORDER BY cs.total_revenue DESC
