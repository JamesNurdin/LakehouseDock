WITH item_reviews AS (
    SELECT
        i.i_item_id,
        i.i_name,
        i.i_category_id,
        i.i_category_name,
        i.i_price,
        i.i_comp_price,
        COUNT(pr.pr_review_id) AS review_cnt,
        AVG(pr.pr_rating) AS avg_rating,
        STDDEV(pr.pr_rating) AS rating_stddev
    FROM items i
    JOIN product_reviews pr
      ON pr.pr_item_id = i.i_item_id
    GROUP BY
        i.i_item_id,
        i.i_name,
        i.i_category_id,
        i.i_category_name,
        i.i_price,
        i.i_comp_price
)
SELECT
    ir.i_item_id,
    ir.i_name,
    ir.i_category_name,
    ir.i_price,
    ir.i_comp_price,
    ir.review_cnt,
    ir.avg_rating,
    ir.rating_stddev,
    ir.i_price / ir.i_comp_price AS price_comp_ratio,
    ROW_NUMBER() OVER (ORDER BY ir.avg_rating DESC, ir.review_cnt DESC) AS rating_rank
FROM item_reviews ir
WHERE ir.review_cnt >= 5
ORDER BY rating_rank
LIMIT 10
