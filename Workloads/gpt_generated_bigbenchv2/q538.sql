/*
  Analytical query: revenue and rating per store and item category
  - Store sales and web sales quantities & revenue
  - Average product rating and review count per category
  - Distinct customer counts for store and web channels
  - Revenue rank of each category within each store
*/
WITH category_ratings AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
store_category_sales AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        i.i_category_id,
        i.i_category_name,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue,
        COUNT(DISTINCT ss.ss_customer_id) AS distinct_store_customers
    FROM store_sales ss
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    GROUP BY s.s_store_id, s.s_store_name, i.i_category_id, i.i_category_name
),
web_category_sales AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS web_revenue,
        COUNT(DISTINCT ws.ws_customer_id) AS distinct_web_customers
    FROM web_sales ws
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
)
SELECT
    scs.s_store_id,
    scs.s_store_name,
    scs.i_category_id,
    scs.i_category_name,
    scs.store_quantity,
    scs.store_revenue,
    wcs.web_quantity,
    wcs.web_revenue,
    cr.avg_rating,
    cr.review_count,
    scs.distinct_store_customers,
    wcs.distinct_web_customers,
    (scs.store_revenue + wcs.web_revenue) AS total_revenue,
    RANK() OVER (PARTITION BY scs.s_store_id ORDER BY (scs.store_revenue + wcs.web_revenue) DESC) AS revenue_rank
FROM store_category_sales scs
LEFT JOIN web_category_sales wcs
    ON scs.i_category_id = wcs.i_category_id
    AND scs.i_category_name = wcs.i_category_name
LEFT JOIN category_ratings cr
    ON scs.i_category_id = cr.i_category_id
    AND scs.i_category_name = cr.i_category_name
ORDER BY total_revenue DESC
LIMIT 100
