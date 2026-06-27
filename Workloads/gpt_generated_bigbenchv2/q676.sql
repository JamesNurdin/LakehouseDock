WITH item_ratings AS (
    SELECT i.i_item_id,
           AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
store_sales_agg AS (
    SELECT ss.ss_item_id AS item_id,
           SUM(ss.ss_quantity) AS store_quantity,
           SUM(ss.ss_quantity * i.i_price) AS store_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_item_id
),
web_sales_agg AS (
    SELECT ws.ws_item_id AS item_id,
           SUM(ws.ws_quantity) AS web_quantity,
           SUM(ws.ws_quantity * i.i_price) AS web_revenue
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY ws.ws_item_id
),
item_customers AS (
    SELECT ss.ss_item_id AS item_id, ss.ss_customer_id AS customer_id
    FROM store_sales ss
    UNION
    SELECT ws.ws_item_id AS item_id, ws.ws_customer_id AS customer_id
    FROM web_sales ws
)
SELECT i.i_item_id,
       i.i_name,
       i.i_category_name,
       COALESCE(sa.store_quantity, 0) AS store_quantity,
       COALESCE(sa.store_revenue, 0) AS store_revenue,
       COALESCE(wa.web_quantity, 0) AS web_quantity,
       COALESCE(wa.web_revenue, 0) AS web_revenue,
       (COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0)) AS total_quantity,
       (COALESCE(sa.store_revenue, 0) + COALESCE(wa.web_revenue, 0)) AS total_revenue,
       r.avg_rating,
       COUNT(DISTINCT ic.customer_id) AS distinct_customers,
       RANK() OVER (ORDER BY (COALESCE(sa.store_revenue, 0) + COALESCE(wa.web_revenue, 0)) DESC) AS revenue_rank
FROM items i
LEFT JOIN store_sales_agg sa ON i.i_item_id = sa.item_id
LEFT JOIN web_sales_agg wa ON i.i_item_id = wa.item_id
LEFT JOIN item_ratings r ON i.i_item_id = r.i_item_id
LEFT JOIN item_customers ic ON i.i_item_id = ic.item_id
GROUP BY i.i_item_id,
         i.i_name,
         i.i_category_name,
         sa.store_quantity,
         sa.store_revenue,
         wa.web_quantity,
         wa.web_revenue,
         r.avg_rating
ORDER BY total_revenue DESC
