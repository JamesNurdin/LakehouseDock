WITH price_agg AS (
    SELECT i_category_id AS category_id,
           i_category AS category,
           AVG(i_price) AS avg_price
    FROM items
    GROUP BY i_category_id, i_category
),
store_sales_agg AS (
    SELECT i.i_category_id AS category_id,
           i.i_category AS category,
           SUM(ss.ss_quantity) AS store_qty
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
web_sales_agg AS (
    SELECT i.i_category_id AS category_id,
           i.i_category AS category,
           SUM(ws.ws_quantity) AS web_qty
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
review_agg AS (
    SELECT i.i_category_id AS category_id,
           i.i_category AS category,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_cnt
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
)
SELECT p.category_id,
       p.category,
       COALESCE(s.store_qty, 0) AS store_qty,
       COALESCE(w.web_qty, 0) AS web_qty,
       COALESCE(r.avg_sentiment, 0) AS avg_sentiment,
       COALESCE(r.review_cnt, 0) AS review_cnt,
       p.avg_price
FROM price_agg p
LEFT JOIN store_sales_agg s ON p.category_id = s.category_id
LEFT JOIN web_sales_agg w ON p.category_id = w.category_id
LEFT JOIN review_agg r ON p.category_id = r.category_id
ORDER BY (COALESCE(s.store_qty, 0) + COALESCE(w.web_qty, 0)) DESC
