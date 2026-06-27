WITH sales_combined AS (
    SELECT ss.ss_item_id AS i_item_id, ss.ss_quantity AS quantity
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_item_id AS i_item_id, ws.ws_quantity AS quantity
    FROM web_sales ws
),
sales_agg AS (
    SELECT
        i.i_item_id,
        i.i_name,
        i.i_category_name,
        i.i_price,
        i.i_comp_price,
        SUM(s.quantity) AS total_quantity_sold
    FROM items i
    LEFT JOIN sales_combined s ON s.i_item_id = i.i_item_id
    GROUP BY i.i_item_id, i.i_name, i.i_category_name, i.i_price, i.i_comp_price
),
reviews_agg AS (
    SELECT
        i.i_item_id,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(pr.pr_review_id) AS review_count
    FROM items i
    LEFT JOIN product_reviews pr ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
)
SELECT
    s.i_item_id,
    s.i_name,
    s.i_category_name,
    s.i_price,
    s.i_comp_price,
    s.total_quantity_sold,
    s.total_quantity_sold * s.i_price AS total_revenue,
    r.avg_rating,
    r.review_count,
    row_number() OVER (ORDER BY s.total_quantity_sold DESC) AS sales_rank
FROM sales_agg s
LEFT JOIN reviews_agg r ON r.i_item_id = s.i_item_id
ORDER BY s.total_quantity_sold DESC
LIMIT 10
