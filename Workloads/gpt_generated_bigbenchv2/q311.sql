WITH review_details AS (
    SELECT
        pr.pr_item_id,
        pr.pr_rating,
        length(pr.pr_content) AS review_len
    FROM product_reviews pr
)
SELECT
    i.i_category_name,
    floor(i.i_price / 10) * 10 AS price_bucket,
    COUNT(*) AS review_count,
    AVG(rd.pr_rating) AS avg_rating,
    AVG(rd.review_len) AS avg_review_length,
    AVG(i.i_price - i.i_comp_price) AS avg_price_diff,
    SUM(CASE WHEN rd.pr_rating = 5 THEN 1 ELSE 0 END) AS five_star_reviews,
    SUM(CASE WHEN rd.pr_rating = 1 THEN 1 ELSE 0 END) AS one_star_reviews
FROM review_details rd
JOIN items i ON rd.pr_item_id = i.i_item_id
GROUP BY i.i_category_name, floor(i.i_price / 10) * 10
ORDER BY avg_rating DESC, review_count DESC
LIMIT 20
