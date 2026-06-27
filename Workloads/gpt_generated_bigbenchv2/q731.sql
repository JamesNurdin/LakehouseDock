WITH review_data AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        i.i_price,
        i.i_comp_price,
        pr.pr_rating
    FROM items i
    JOIN product_reviews pr
        ON pr.pr_item_id = i.i_item_id
),
price_bucketed AS (
    SELECT
        i_category_id,
        i_category_name,
        CAST(i_price / 10 AS integer) * 10 AS price_bucket_start,
        i_price,
        i_comp_price,
        pr_rating
    FROM review_data
)
SELECT
    i_category_id,
    i_category_name,
    price_bucket_start,
    COUNT(*) AS review_count,
    AVG(pr_rating) AS avg_rating,
    AVG(i_price) AS avg_price,
    AVG(i_price - i_comp_price) AS avg_price_diff
FROM price_bucketed
GROUP BY i_category_id, i_category_name, price_bucket_start
HAVING COUNT(*) >= 10
ORDER BY i_category_id, price_bucket_start
