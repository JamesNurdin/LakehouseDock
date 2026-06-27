WITH rating_per_item AS (
    SELECT pr_item_id,
           AVG(pr_rating) AS avg_rating
    FROM product_reviews
    GROUP BY pr_item_id
),
category_rating AS (
    SELECT i.i_category_name AS i_category_name,
           AVG(r.avg_rating) AS avg_rating
    FROM items i
    LEFT JOIN rating_per_item r
        ON i.i_item_id = r.pr_item_id
    GROUP BY i.i_category_name
),
store_sales_agg AS (
    SELECT i.i_category_name AS i_category_name,
           SUM(ss.ss_quantity) AS store_quantity,
           SUM(ss.ss_quantity * i.i_price) AS store_revenue,
           COUNT(DISTINCT ss.ss_customer_id) AS store_customers
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category_name
),
web_sales_agg AS (
    SELECT i.i_category_name AS i_category_name,
           SUM(ws.ws_quantity) AS web_quantity,
           SUM(ws.ws_quantity * i.i_price) AS web_revenue,
           COUNT(DISTINCT ws.ws_customer_id) AS web_customers
    FROM web_sales ws
    JOIN items i
        ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_name
)
SELECT COALESCE(ss.i_category_name, ws.i_category_name) AS i_category_name,
       ss.store_quantity,
       ss.store_revenue,
       ws.web_quantity,
       ws.web_revenue,
       (COALESCE(ss.store_quantity, 0) + COALESCE(ws.web_quantity, 0)) AS total_quantity,
       (COALESCE(ss.store_revenue, 0) + COALESCE(ws.web_revenue, 0)) AS total_revenue,
       (COALESCE(ss.store_customers, 0) + COALESCE(ws.web_customers, 0)) AS distinct_customers,
       cr.avg_rating
FROM store_sales_agg ss
FULL OUTER JOIN web_sales_agg ws
    ON ss.i_category_name = ws.i_category_name
LEFT JOIN category_rating cr
    ON COALESCE(ss.i_category_name, ws.i_category_name) = cr.i_category_name
ORDER BY total_revenue DESC
LIMIT 20
