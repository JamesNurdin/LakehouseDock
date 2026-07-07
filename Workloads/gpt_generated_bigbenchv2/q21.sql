WITH store_sales_agg AS (
    SELECT i.i_category,
           SUM(ss.ss_quantity) AS total_store_qty
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category
),
web_sales_agg AS (
    SELECT i.i_category,
           SUM(ws.ws_quantity) AS total_web_qty
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category
),
review_agg AS (
    SELECT i.i_category,
           COUNT(pr.pr_review_id) AS review_count,
           AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category
),
item_stats AS (
    SELECT i.i_category,
           AVG(i.i_price) AS avg_price,
           AVG(i.i_comp_price) AS avg_comp_price
    FROM items i
    GROUP BY i.i_category
)
SELECT istats.i_category,
       istats.avg_price,
       istats.avg_comp_price,
       ra.review_count,
       ra.avg_sentiment,
       COALESCE(ssa.total_store_qty, 0) AS total_store_quantity,
       COALESCE(wsa.total_web_qty, 0) AS total_web_quantity
FROM item_stats istats
LEFT JOIN review_agg ra ON istats.i_category = ra.i_category
LEFT JOIN store_sales_agg ssa ON istats.i_category = ssa.i_category
LEFT JOIN web_sales_agg wsa ON istats.i_category = wsa.i_category
ORDER BY istats.i_category
