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
reviews_agg AS (
    SELECT pr_item_id,
           COUNT(*) AS review_cnt,
           AVG(pr_rating) AS avg_rating
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT
    i.i_item_id,
    i.i_name,
    i.i_category_id,
    i.i_category_name,
    i.i_price,
    i.i_comp_price,
    ss.store_qty,
    ws.web_qty,
    COALESCE(ss.store_qty, 0) + COALESCE(ws.web_qty, 0) AS total_quantity,
    r.review_cnt,
    r.avg_rating,
    i.i_price - i.i_comp_price AS price_difference,
    RANK() OVER (
        PARTITION BY i.i_category_id
        ORDER BY COALESCE(ss.store_qty, 0) + COALESCE(ws.web_qty, 0) DESC
    ) AS category_rank
FROM items i
LEFT JOIN store_sales_agg ss
    ON i.i_item_id = ss.ss_item_id
LEFT JOIN web_sales_agg ws
    ON i.i_item_id = ws.ws_item_id
LEFT JOIN reviews_agg r
    ON i.i_item_id = r.pr_item_id
WHERE i.i_price > 0
ORDER BY total_quantity DESC, price_difference DESC
LIMIT 10
