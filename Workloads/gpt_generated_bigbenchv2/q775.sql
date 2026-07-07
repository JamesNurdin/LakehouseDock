WITH store_sales_agg AS (
    SELECT i.i_item_id,
           SUM(ss.ss_quantity) AS store_qty
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
web_sales_agg AS (
    SELECT i.i_item_id,
           SUM(ws.ws_quantity) AS web_qty
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
reviews_agg AS (
    SELECT i.i_item_id,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_cnt
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
)
SELECT i.i_category_id,
       i.i_category,
       SUM(COALESCE(ssa.store_qty, 0) + COALESCE(wsa.web_qty, 0)) AS total_quantity_sold,
       CASE WHEN SUM(r.review_cnt) > 0
            THEN SUM(r.avg_sentiment * r.review_cnt) / SUM(r.review_cnt)
            ELSE NULL END AS avg_review_sentiment,
       SUM(r.review_cnt) AS total_reviews
FROM items i
LEFT JOIN store_sales_agg ssa ON i.i_item_id = ssa.i_item_id
LEFT JOIN web_sales_agg wsa ON i.i_item_id = wsa.i_item_id
LEFT JOIN reviews_agg r ON i.i_item_id = r.i_item_id
GROUP BY i.i_category_id, i.i_category
ORDER BY total_quantity_sold DESC
LIMIT 10
