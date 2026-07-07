WITH store_sales_agg AS (
    SELECT ss_item_id,
           SUM(ss_quantity) AS total_store_quantity
    FROM store_sales
    GROUP BY ss_item_id
),
web_sales_agg AS (
    SELECT ws_item_id,
           SUM(ws_quantity) AS total_web_quantity
    FROM web_sales
    GROUP BY ws_item_id
),
item_sales AS (
    SELECT i.i_item_id,
           i.i_category,
           i.i_category_id,
           i.i_price,
           COALESCE(s.total_store_quantity, 0) + COALESCE(w.total_web_quantity, 0) AS total_quantity_sold
    FROM items i
    LEFT JOIN store_sales_agg s ON i.i_item_id = s.ss_item_id
    LEFT JOIN web_sales_agg w ON i.i_item_id = w.ws_item_id
),
item_reviews AS (
    SELECT pr.pr_item_id,
           COUNT(*) AS review_count,
           AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT i.i_category,
       i.i_category_id,
       COUNT(DISTINCT i.i_item_id) AS distinct_items,
       SUM(i.total_quantity_sold) AS total_quantity_sold,
       SUM(i.i_price * i.total_quantity_sold) / NULLIF(SUM(i.total_quantity_sold), 0) AS avg_price_weighted,
       SUM(COALESCE(r.review_count, 0)) AS total_reviews,
       AVG(r.avg_sentiment) AS avg_sentiment_across_items
FROM item_sales i
LEFT JOIN item_reviews r ON i.i_item_id = r.pr_item_id
GROUP BY i.i_category, i.i_category_id
ORDER BY total_quantity_sold DESC
LIMIT 10
