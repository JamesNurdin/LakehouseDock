/* Category‑level product review and pricing analysis */
WITH item_reviews AS (
    SELECT
        pr.pr_item_id,
        COUNT(pr.pr_review_id) AS review_cnt,
        AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT
    i.i_category_id,
    i.i_category_name,
    AVG(i.i_price) AS avg_price,
    AVG(i.i_comp_price) AS avg_comp_price,
    AVG((i.i_comp_price - i.i_price) / i.i_comp_price * 100) AS avg_discount_pct,
    AVG(ir.avg_rating) AS avg_category_rating,
    SUM(ir.review_cnt) AS total_reviews
FROM items i
JOIN item_reviews ir
    ON ir.pr_item_id = i.i_item_id
GROUP BY i.i_category_id, i.i_category_name
HAVING SUM(ir.review_cnt) >= 10
ORDER BY avg_category_rating DESC
LIMIT 10
