WITH store_sales_agg AS (
    SELECT ss_item_id,
           SUM(ss_quantity) AS store_qty
    FROM store_sales
    GROUP BY ss_item_id
),
web_sales_agg AS (
    SELECT ws_item_id,
           SUM(ws_quantity) AS web_qty
    FROM web_sales
    GROUP BY ws_item_id
),
sales AS (
    SELECT i.i_item_id,
           i.i_category_id,
           i.i_category,
           i.i_price,
           COALESCE(s.store_qty, 0) + COALESCE(w.web_qty, 0) AS total_qty,
           (COALESCE(s.store_qty, 0) + COALESCE(w.web_qty, 0)) * i.i_price AS revenue
    FROM items i
    LEFT JOIN store_sales_agg s
        ON s.ss_item_id = i.i_item_id
    LEFT JOIN web_sales_agg w
        ON w.ws_item_id = i.i_item_id
),
reviews AS (
    SELECT pr_item_id,
           AVG(pr_sentiment) AS avg_sentiment
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT
    s.i_category_id,
    s.i_category,
    SUM(s.total_qty) AS total_quantity_sold,
    SUM(s.revenue) AS total_revenue,
    AVG(r.avg_sentiment) AS avg_review_sentiment
FROM sales s
LEFT JOIN reviews r
    ON r.pr_item_id = s.i_item_id
GROUP BY s.i_category_id, s.i_category
ORDER BY total_quantity_sold DESC
LIMIT 10
