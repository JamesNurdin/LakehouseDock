WITH store_sales_agg AS (
    SELECT ss_item_id,
           sum(ss_quantity) AS total_store_quantity
    FROM store_sales
    GROUP BY ss_item_id
),
web_sales_agg AS (
    SELECT ws_item_id,
           sum(ws_quantity) AS total_web_quantity
    FROM web_sales
    GROUP BY ws_item_id
),
reviews_agg AS (
    SELECT pr_item_id,
           avg(pr_rating) AS avg_rating
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT
    i.i_category_id,
    i.i_category_name,
    sum(coalesce(ssa.total_store_quantity, 0)) AS total_store_quantity,
    sum(coalesce(wsa.total_web_quantity, 0)) AS total_web_quantity,
    avg(r.avg_rating) AS avg_rating,
    avg(i.i_price) AS avg_price,
    avg(i.i_comp_price) AS avg_comp_price
FROM items i
LEFT JOIN store_sales_agg ssa
    ON ssa.ss_item_id = i.i_item_id
LEFT JOIN web_sales_agg wsa
    ON wsa.ws_item_id = i.i_item_id
LEFT JOIN reviews_agg r
    ON r.pr_item_id = i.i_item_id
GROUP BY i.i_category_id, i.i_category_name
ORDER BY total_store_quantity DESC, total_web_quantity DESC
LIMIT 20
