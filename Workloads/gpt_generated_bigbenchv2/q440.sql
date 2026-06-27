WITH sales_agg AS (
    SELECT
        ss.ss_item_id,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_sales_amount
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_item_id
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
    i.i_category_id,
    i.i_category_name,
    COUNT(DISTINCT i.i_item_id) AS distinct_items,
    SUM(COALESCE(s.total_quantity, 0)) AS total_quantity_sold,
    SUM(COALESCE(s.total_sales_amount, 0)) AS total_sales_amount,
    AVG(i.i_price) AS avg_item_price,
    SUM(COALESCE(r.review_count, 0)) AS total_review_count,
    CASE WHEN SUM(COALESCE(r.review_count, 0)) > 0
         THEN SUM(COALESCE(r.avg_rating * r.review_count, 0)) / SUM(COALESCE(r.review_count, 0))
         ELSE NULL
    END AS avg_category_rating
FROM items i
LEFT JOIN sales_agg s
    ON i.i_item_id = s.ss_item_id
LEFT JOIN reviews_agg r
    ON i.i_item_id = r.pr_item_id
GROUP BY
    i.i_category_id,
    i.i_category_name
ORDER BY total_sales_amount DESC
LIMIT 10
