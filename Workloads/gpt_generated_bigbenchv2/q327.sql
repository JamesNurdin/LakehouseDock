/*
  Store‑level and category performance for items with customer reviews.
  Shows the top 10 stores‑category combinations by revenue, together with
  total quantity sold, average item rating (based on product reviews), and
  the count of distinct items sold.
*/
WITH avg_item_rating AS (
    SELECT
        pr_item_id,
        avg(pr_rating) AS avg_rating
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT
    s.s_store_name,
    i.i_category_name,
    sum(ss.ss_quantity) AS total_quantity,
    sum(ss.ss_quantity * i.i_price) AS total_revenue,
    avg(r.avg_rating) AS avg_item_rating,
    count(distinct i.i_item_id) AS distinct_items_sold
FROM store_sales ss
JOIN items i
    ON ss.ss_item_id = i.i_item_id
JOIN stores s
    ON ss.ss_store_id = s.s_store_id
LEFT JOIN avg_item_rating r
    ON i.i_item_id = r.pr_item_id
GROUP BY
    s.s_store_name,
    i.i_category_name
ORDER BY total_revenue DESC
LIMIT 10
