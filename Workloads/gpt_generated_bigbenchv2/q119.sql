WITH store_agg AS (
    SELECT i.i_category,
           SUM(ss.ss_quantity) AS total_store_quantity,
           COUNT(DISTINCT ss.ss_customer_id) AS distinct_store_customers
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category
),
web_agg AS (
    SELECT i.i_category,
           SUM(ws.ws_quantity) AS total_web_quantity,
           COUNT(DISTINCT ws.ws_customer_id) AS distinct_web_customers
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category
),
review_agg AS (
    SELECT i.i_category,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category
),
price_agg AS (
    SELECT i.i_category,
           AVG(i.i_price) AS avg_price
    FROM items i
    GROUP BY i.i_category
)
SELECT coalesce(s.i_category, w.i_category, r.i_category, p.i_category) AS category,
       s.total_store_quantity,
       w.total_web_quantity,
       s.distinct_store_customers,
       w.distinct_web_customers,
       r.avg_sentiment,
       r.review_count,
       p.avg_price
FROM store_agg s
FULL OUTER JOIN web_agg w ON s.i_category = w.i_category
FULL OUTER JOIN review_agg r ON coalesce(s.i_category, w.i_category) = r.i_category
FULL OUTER JOIN price_agg p ON coalesce(s.i_category, w.i_category, r.i_category) = p.i_category
ORDER BY category
