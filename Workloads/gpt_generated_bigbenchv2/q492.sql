/* Analytical query: revenue, quantity, and review metrics per item category */
WITH sales_per_item AS (
    SELECT
        i.i_item_id,
        i.i_category_name,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue,
        SUM(ss.ss_quantity) AS store_quantity,
        COUNT(DISTINCT ss.ss_customer_id) AS store_customer_count,
        COUNT(DISTINCT ss.ss_store_id) AS store_store_count
    FROM store_sales ss
    JOIN items i
      ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_item_id, i.i_category_name
),
web_sales_per_item AS (
    SELECT
        i.i_item_id,
        i.i_category_name,
        SUM(ws.ws_quantity * i.i_price) AS web_revenue,
        SUM(ws.ws_quantity) AS web_quantity,
        COUNT(DISTINCT ws.ws_customer_id) AS web_customer_count
    FROM web_sales ws
    JOIN items i
      ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_item_id, i.i_category_name
),
combined_sales AS (
    SELECT
        COALESCE(s.i_item_id, w.i_item_id) AS i_item_id,
        COALESCE(s.i_category_name, w.i_category_name) AS i_category_name,
        COALESCE(s.store_revenue, 0) + COALESCE(w.web_revenue, 0) AS total_revenue,
        COALESCE(s.store_quantity, 0) + COALESCE(w.web_quantity, 0) AS total_quantity,
        COALESCE(s.store_customer_count, 0) + COALESCE(w.web_customer_count, 0) AS total_customer_count,
        COALESCE(s.store_store_count, 0) AS total_store_count
    FROM sales_per_item s
    FULL OUTER JOIN web_sales_per_item w
      ON s.i_item_id = w.i_item_id
),
reviews_per_item AS (
    SELECT
        i.i_item_id,
        i.i_category_name,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i
      ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id, i.i_category_name
),
category_agg AS (
    SELECT
        c.i_category_name,
        SUM(c.total_revenue) AS category_total_revenue,
        SUM(c.total_quantity) AS category_total_quantity,
        AVG(r.avg_rating) AS category_avg_rating,
        SUM(r.review_count) AS category_review_count,
        COUNT(DISTINCT c.i_item_id) AS distinct_items_sold,
        SUM(c.total_customer_count) AS category_total_customers,
        SUM(c.total_store_count) AS category_total_stores
    FROM combined_sales c
    LEFT JOIN reviews_per_item r
      ON c.i_item_id = r.i_item_id
    GROUP BY c.i_category_name
)
SELECT
    ca.i_category_name,
    ca.category_total_revenue,
    ca.category_total_quantity,
    ca.category_avg_rating,
    ca.category_review_count,
    ca.distinct_items_sold,
    ca.category_total_customers,
    ca.category_total_stores,
    RANK() OVER (ORDER BY ca.category_total_revenue DESC) AS revenue_rank
FROM category_agg ca
ORDER BY revenue_rank
LIMIT 10
