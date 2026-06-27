WITH store_agg AS (
    SELECT i.i_category_name AS category,
           SUM(ss.ss_quantity) AS store_quantity,
           COUNT(DISTINCT ss.ss_customer_id) AS store_customer_count,
           SUM(ss.ss_quantity * i.i_price) AS store_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    GROUP BY i.i_category_name
),
web_agg AS (
    SELECT i.i_category_name AS category,
           SUM(ws.ws_quantity) AS web_quantity,
           COUNT(DISTINCT ws.ws_customer_id) AS web_customer_count,
           SUM(ws.ws_quantity * i.i_price) AS web_revenue
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    GROUP BY i.i_category_name
),
review_agg AS (
    SELECT i.i_category_name AS category,
           AVG(pr.pr_rating) AS avg_rating,
           COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_name
),
price_agg AS (
    SELECT i.i_category_name AS category,
           AVG(i.i_price) AS avg_price,
           AVG(i.i_comp_price) AS avg_comp_price
    FROM items i
    GROUP BY i.i_category_name
)
SELECT COALESCE(s.category, w.category, r.category, p.category) AS category,
       s.store_quantity,
       w.web_quantity,
       s.store_customer_count,
       w.web_customer_count,
       s.store_revenue,
       w.web_revenue,
       r.avg_rating,
       r.review_count,
       p.avg_price,
       p.avg_comp_price
FROM store_agg s
FULL OUTER JOIN web_agg w ON s.category = w.category
FULL OUTER JOIN review_agg r ON COALESCE(s.category, w.category) = r.category
FULL OUTER JOIN price_agg p ON COALESCE(s.category, w.category, r.category) = p.category
ORDER BY category
