WITH sales_union AS (
    -- Combine store and web sales for each item, calculating revenue using the item price
    SELECT
        i.i_item_id,
        i.i_name,
        i.i_category_name,
        ss.ss_quantity AS quantity,
        ss.ss_quantity * i.i_price AS revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    UNION ALL
    SELECT
        i.i_item_id,
        i.i_name,
        i.i_category_name,
        ws.ws_quantity AS quantity,
        ws.ws_quantity * i.i_price AS revenue
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
),
sales_agg AS (
    -- Aggregate total quantity sold and total revenue per item across both channels
    SELECT
        i_item_id,
        i_name,
        i_category_name,
        SUM(quantity) AS total_quantity,
        SUM(revenue) AS total_revenue
    FROM sales_union
    GROUP BY i_item_id, i_name, i_category_name
),
review_agg AS (
    -- Compute review statistics per item
    SELECT
        i.i_item_id,
        COUNT(pr.pr_review_id) AS review_count,
        AVG(pr.pr_rating) AS avg_rating
    FROM items i
    LEFT JOIN product_reviews pr ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
)
SELECT
    s.i_item_id,
    s.i_name,
    s.i_category_name,
    s.total_quantity,
    s.total_revenue,
    COALESCE(r.review_count, 0) AS review_count,
    r.avg_rating
FROM sales_agg s
LEFT JOIN review_agg r ON r.i_item_id = s.i_item_id
ORDER BY s.total_revenue DESC
LIMIT 10
