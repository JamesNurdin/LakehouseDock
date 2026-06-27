WITH
    store_agg AS (
        SELECT i.i_category_name,
               SUM(ss.ss_quantity) AS store_quantity,
               SUM(i.i_price * ss.ss_quantity) AS store_revenue,
               COUNT(DISTINCT ss.ss_customer_id) AS store_customer_cnt
        FROM store_sales ss
        JOIN items i ON ss.ss_item_id = i.i_item_id
        GROUP BY i.i_category_name
    ),
    web_agg AS (
        SELECT i.i_category_name,
               SUM(ws.ws_quantity) AS web_quantity,
               SUM(i.i_price * ws.ws_quantity) AS web_revenue,
               COUNT(DISTINCT ws.ws_customer_id) AS web_customer_cnt
        FROM web_sales ws
        JOIN items i ON ws.ws_item_id = i.i_item_id
        GROUP BY i.i_category_name
    ),
    rating_agg AS (
        SELECT i.i_category_name,
               AVG(pr.pr_rating) AS avg_rating,
               COUNT(*) AS review_cnt
        FROM product_reviews pr
        JOIN items i ON pr.pr_item_id = i.i_item_id
        GROUP BY i.i_category_name
    ),
    customer_agg AS (
        SELECT i_category_name,
               COUNT(DISTINCT cust_id) AS distinct_customer_cnt
        FROM (
            SELECT ss.ss_customer_id AS cust_id,
                   i.i_category_name
            FROM store_sales ss
            JOIN items i ON ss.ss_item_id = i.i_item_id
            UNION ALL
            SELECT ws.ws_customer_id AS cust_id,
                   i.i_category_name
            FROM web_sales ws
            JOIN items i ON ws.ws_item_id = i.i_item_id
        ) AS combined
        GROUP BY i_category_name
    )
SELECT COALESCE(s.i_category_name, w.i_category_name, r.i_category_name, c.i_category_name) AS category,
       COALESCE(s.store_quantity, 0) AS total_store_quantity,
       COALESCE(w.web_quantity, 0) AS total_web_quantity,
       COALESCE(s.store_revenue, 0) AS total_store_revenue,
       COALESCE(w.web_revenue, 0) AS total_web_revenue,
       COALESCE(r.avg_rating, 0) AS average_rating,
       COALESCE(r.review_cnt, 0) AS review_count,
       COALESCE(c.distinct_customer_cnt, 0) AS distinct_customer_count
FROM store_agg s
FULL OUTER JOIN web_agg w ON s.i_category_name = w.i_category_name
FULL OUTER JOIN rating_agg r ON COALESCE(s.i_category_name, w.i_category_name) = r.i_category_name
FULL OUTER JOIN customer_agg c ON COALESCE(s.i_category_name, w.i_category_name, r.i_category_name) = c.i_category_name
ORDER BY category
