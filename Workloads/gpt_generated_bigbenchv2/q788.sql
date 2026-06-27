WITH category_base AS (
    SELECT DISTINCT i_category_name
    FROM items
)
SELECT
    cb.i_category_name,
    (SELECT avg(i2.i_price)
     FROM items i2
     WHERE i2.i_category_name = cb.i_category_name) AS avg_price,
    (SELECT count(DISTINCT i3.i_item_id)
     FROM items i3
     WHERE i3.i_category_name = cb.i_category_name) AS distinct_item_count,
    coalesce(
        (SELECT sum(ss.ss_quantity)
         FROM store_sales ss
         JOIN items i4 ON ss.ss_item_id = i4.i_item_id
         WHERE i4.i_category_name = cb.i_category_name), 0
    ) + coalesce(
        (SELECT sum(ws.ws_quantity)
         FROM web_sales ws
         JOIN items i5 ON ws.ws_item_id = i5.i_item_id
         WHERE i5.i_category_name = cb.i_category_name), 0
    ) AS total_quantity,
    (SELECT avg(pr.pr_rating)
     FROM product_reviews pr
     JOIN items i6 ON pr.pr_item_id = i6.i_item_id
     WHERE i6.i_category_name = cb.i_category_name) AS avg_rating,
    (SELECT count(pr.pr_review_id)
     FROM product_reviews pr
     JOIN items i7 ON pr.pr_item_id = i7.i_item_id
     WHERE i7.i_category_name = cb.i_category_name) AS review_count
FROM category_base cb
ORDER BY total_quantity DESC
LIMIT 10
