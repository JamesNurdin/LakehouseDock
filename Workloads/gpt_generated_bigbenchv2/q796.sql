WITH sales_agg AS (
    SELECT
        ws.ws_item_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_quantity * i.i_price) AS total_revenue
    FROM web_sales ws
    JOIN items i
        ON ws.ws_item_id = i.i_item_id
    GROUP BY ws.ws_item_id
),
reviews_agg AS (
    SELECT
        pr.pr_item_id,
        COUNT(*) AS review_count,
        AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT
    i.i_item_id,
    i.i_name,
    i.i_category_id,
    i.i_category_name,
    i.i_price,
    COALESCE(s.total_quantity, 0) AS total_quantity,
    COALESCE(s.total_revenue, 0) AS total_revenue,
    COALESCE(r.review_count, 0) AS review_count,
    r.avg_rating,
    RANK() OVER (
        PARTITION BY i.i_category_id
        ORDER BY COALESCE(s.total_revenue, 0) DESC
    ) AS revenue_rank_within_category
FROM items i
LEFT JOIN sales_agg s
    ON i.i_item_id = s.ws_item_id
LEFT JOIN reviews_agg r
    ON i.i_item_id = r.pr_item_id
ORDER BY i.i_category_id, revenue_rank_within_category
