WITH sales_agg AS (
    SELECT
        i.i_item_id,
        i.i_category_id,
        i.i_category_name,
        i.i_price,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_sales_amount
    FROM items i
    JOIN store_sales ss
        ON i.i_item_id = ss.ss_item_id
    GROUP BY i.i_item_id, i.i_category_id, i.i_category_name, i.i_price
),
reviews_agg AS (
    SELECT
        i.i_item_id,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(pr.pr_review_id) AS review_count
    FROM items i
    JOIN product_reviews pr
        ON i.i_item_id = pr.pr_item_id
    GROUP BY i.i_item_id
)
SELECT
    s.i_category_name,
    COUNT(DISTINCT s.i_item_id) AS distinct_items,
    SUM(s.total_quantity) AS total_quantity_sold,
    SUM(s.total_sales_amount) AS total_sales_amount,
    AVG(r.avg_rating) AS avg_item_rating,
    SUM(r.review_count) AS total_reviews
FROM sales_agg s
LEFT JOIN reviews_agg r
    ON s.i_item_id = r.i_item_id
GROUP BY s.i_category_name
ORDER BY total_sales_amount DESC
