WITH store_rev AS (
    SELECT i.i_category,
           SUM(ss.ss_quantity * i.i_price) AS store_revenue,
           SUM(ss.ss_quantity) AS store_units_sold
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category
),
web_rev AS (
    SELECT i.i_category,
           SUM(ws.ws_quantity * i.i_price) AS web_revenue,
           SUM(ws.ws_quantity) AS web_units_sold
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category
),
review_stats AS (
    SELECT i.i_category,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category
)
SELECT COALESCE(sr.i_category, wr.i_category, rs.i_category) AS category,
       COALESCE(sr.store_revenue, 0) AS store_revenue,
       COALESCE(wr.web_revenue, 0) AS web_revenue,
       COALESCE(sr.store_units_sold, 0) AS store_units_sold,
       COALESCE(wr.web_units_sold, 0) AS web_units_sold,
       COALESCE(rs.avg_sentiment, 0) AS avg_sentiment,
       COALESCE(rs.review_count, 0) AS review_count
FROM store_rev sr
FULL OUTER JOIN web_rev wr ON sr.i_category = wr.i_category
FULL OUTER JOIN review_stats rs ON COALESCE(sr.i_category, wr.i_category) = rs.i_category
ORDER BY (COALESCE(sr.store_revenue, 0) + COALESCE(wr.web_revenue, 0)) DESC
LIMIT 10
