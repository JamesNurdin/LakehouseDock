WITH store_sales_agg AS (
    SELECT i.i_category_id,
           i.i_category,
           SUM(ss.ss_quantity) AS store_quantity,
           COUNT(DISTINCT ss.ss_customer_id) AS store_customers
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
web_sales_agg AS (
    SELECT i.i_category_id,
           i.i_category,
           SUM(ws.ws_quantity) AS web_quantity,
           COUNT(DISTINCT ws.ws_customer_id) AS web_customers
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
sales_by_category AS (
    SELECT COALESCE(s.i_category_id, w.i_category_id) AS i_category_id,
           COALESCE(s.i_category, w.i_category) AS i_category,
           COALESCE(s.store_quantity, 0) + COALESCE(w.web_quantity, 0) AS total_quantity,
           COALESCE(s.store_customers, 0) + COALESCE(w.web_customers, 0) AS distinct_customers_estimate
    FROM store_sales_agg s
    FULL OUTER JOIN web_sales_agg w
        ON s.i_category_id = w.i_category_id
),
reviews_by_category AS (
    SELECT i.i_category_id,
           i.i_category,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
price_stats_by_category AS (
    SELECT i.i_category_id,
           i.i_category,
           AVG(i.i_price) AS avg_price,
           AVG(i.i_comp_price) AS avg_comp_price,
           AVG(i.i_price - i.i_comp_price) AS avg_price_diff
    FROM items i
    GROUP BY i.i_category_id, i.i_category
)
SELECT s.i_category_id,
       s.i_category,
       s.total_quantity,
       s.distinct_customers_estimate AS distinct_customers,
       r.avg_sentiment,
       r.review_count,
       p.avg_price,
       p.avg_comp_price,
       p.avg_price_diff
FROM sales_by_category s
LEFT JOIN reviews_by_category r
    ON s.i_category_id = r.i_category_id
LEFT JOIN price_stats_by_category p
    ON s.i_category_id = p.i_category_id
ORDER BY s.total_quantity DESC
