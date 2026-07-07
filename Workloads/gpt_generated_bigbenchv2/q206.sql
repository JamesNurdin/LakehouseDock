WITH sales_agg AS (
    SELECT ss_item_id AS item_id, SUM(ss_quantity) AS total_qty
    FROM store_sales
    GROUP BY ss_item_id
    UNION ALL
    SELECT ws_item_id AS item_id, SUM(ws_quantity) AS total_qty
    FROM web_sales
    GROUP BY ws_item_id
),
combined_sales AS (
    SELECT item_id, SUM(total_qty) AS total_qty
    FROM sales_agg
    GROUP BY item_id
),
review_agg AS (
    SELECT pr_item_id,
           AVG(pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT i.i_category,
       i.i_category_id,
       COUNT(DISTINCT i.i_item_id) AS distinct_items,
       SUM(cs.total_qty) AS total_quantity_sold,
       AVG(cs.total_qty * i.i_price) / NULLIF(SUM(cs.total_qty), 0) AS avg_price_weighted,
       AVG(r.avg_sentiment) AS avg_sentiment,
       SUM(r.review_count) AS total_reviews
FROM combined_sales cs
JOIN items i
  ON cs.item_id = i.i_item_id
LEFT JOIN review_agg r
  ON i.i_item_id = r.pr_item_id
GROUP BY i.i_category, i.i_category_id
ORDER BY total_quantity_sold DESC
LIMIT 10
