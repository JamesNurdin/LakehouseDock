WITH
    store_sales_agg AS (
        SELECT
            i.i_item_id,
            SUM(ss.ss_quantity) AS store_quantity,
            SUM(ss.ss_quantity * i.i_price) AS store_revenue
        FROM store_sales ss
        JOIN items i ON ss.ss_item_id = i.i_item_id
        GROUP BY i.i_item_id
    ),
    web_sales_agg AS (
        SELECT
            i.i_item_id,
            SUM(ws.ws_quantity) AS web_quantity,
            SUM(ws.ws_quantity * i.i_price) AS web_revenue
        FROM web_sales ws
        JOIN items i ON ws.ws_item_id = i.i_item_id
        GROUP BY i.i_item_id
    ),
    reviews_agg AS (
        SELECT
            i.i_item_id,
            SUM(pr.pr_rating) AS rating_sum,
            COUNT(*) AS rating_count
        FROM product_reviews pr
        JOIN items i ON pr.pr_item_id = i.i_item_id
        GROUP BY i.i_item_id
    ),
    category_sales AS (
        SELECT
            i.i_category_id,
            i.i_category_name,
            SUM(COALESCE(ssa.store_quantity, 0) + COALESCE(wsa.web_quantity, 0)) AS total_quantity,
            SUM(COALESCE(ssa.store_revenue, 0) + COALESCE(wsa.web_revenue, 0)) AS total_revenue
        FROM items i
        LEFT JOIN store_sales_agg ssa ON i.i_item_id = ssa.i_item_id
        LEFT JOIN web_sales_agg wsa ON i.i_item_id = wsa.i_item_id
        GROUP BY i.i_category_id, i.i_category_name
    ),
    category_reviews AS (
        SELECT
            i.i_category_id,
            i.i_category_name,
            SUM(COALESCE(r.rating_sum, 0)) AS rating_sum,
            SUM(COALESCE(r.rating_count, 0)) AS rating_count
        FROM items i
        LEFT JOIN reviews_agg r ON i.i_item_id = r.i_item_id
        GROUP BY i.i_category_id, i.i_category_name
    ),
    category_customers AS (
        SELECT
            i.i_category_id,
            i.i_category_name,
            COUNT(DISTINCT cust.customer_id) AS distinct_customers
        FROM (
            SELECT ss.ss_customer_id AS customer_id, ss.ss_item_id AS item_id FROM store_sales ss
            UNION ALL
            SELECT ws.ws_customer_id AS customer_id, ws.ws_item_id AS item_id FROM web_sales ws
        ) cust
        JOIN items i ON cust.item_id = i.i_item_id
        GROUP BY i.i_category_id, i.i_category_name
    )
SELECT
    cs.i_category_id,
    cs.i_category_name,
    cs.total_quantity,
    cs.total_revenue,
    cr.rating_sum,
    cr.rating_count,
    CASE WHEN cr.rating_count > 0 THEN cr.rating_sum / cr.rating_count END AS avg_rating,
    cc.distinct_customers
FROM category_sales cs
JOIN category_reviews cr
  ON cs.i_category_id = cr.i_category_id
 AND cs.i_category_name = cr.i_category_name
JOIN category_customers cc
  ON cs.i_category_id = cc.i_category_id
 AND cs.i_category_name = cc.i_category_name
ORDER BY cs.total_revenue DESC
LIMIT 10
