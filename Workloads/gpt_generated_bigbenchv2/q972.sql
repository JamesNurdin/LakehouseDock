WITH store_sales_agg AS (
    SELECT ss.ss_item_id AS i_item_id,
           sum(ss.ss_quantity) AS total_quantity_store,
           sum(ss.ss_quantity * i.i_price) AS total_revenue_store
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_item_id
),
web_sales_agg AS (
    SELECT ws.ws_item_id AS i_item_id,
           sum(ws.ws_quantity) AS total_quantity_web,
           sum(ws.ws_quantity * i.i_price) AS total_revenue_web
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY ws.ws_item_id
),
product_reviews_agg AS (
    SELECT pr.pr_item_id AS i_item_id,
           avg(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
),
distinct_customers_per_item AS (
    SELECT ss.ss_item_id AS i_item_id,
           ss.ss_customer_id AS c_customer_id
    FROM store_sales ss
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    UNION
    SELECT ws.ws_item_id AS i_item_id,
           ws.ws_customer_id AS c_customer_id
    FROM web_sales ws
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
),
distinct_customers_agg AS (
    SELECT i_item_id,
           count(DISTINCT c_customer_id) AS distinct_customers
    FROM distinct_customers_per_item
    GROUP BY i_item_id
)
SELECT i.i_item_id,
       i.i_name,
       i.i_category_name,
       coalesce(ss.total_quantity_store, 0) + coalesce(ws.total_quantity_web, 0) AS total_quantity_sold,
       coalesce(ss.total_revenue_store, 0) + coalesce(ws.total_revenue_web, 0) AS total_revenue,
       coalesce(pr.avg_rating, 0) AS avg_rating,
       coalesce(dc.distinct_customers, 0) AS distinct_customers
FROM items i
LEFT JOIN store_sales_agg ss ON i.i_item_id = ss.i_item_id
LEFT JOIN web_sales_agg ws ON i.i_item_id = ws.i_item_id
LEFT JOIN product_reviews_agg pr ON i.i_item_id = pr.i_item_id
LEFT JOIN distinct_customers_agg dc ON i.i_item_id = dc.i_item_id
ORDER BY total_quantity_sold DESC
LIMIT 10
