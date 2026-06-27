WITH combined_sales AS (
    SELECT ss_item_id AS item_id,
           ss_quantity AS quantity
    FROM store_sales
    UNION ALL
    SELECT ws_item_id AS item_id,
           ws_quantity AS quantity
    FROM web_sales
),
sales_agg AS (
    SELECT item_id,
           SUM(quantity) AS total_quantity
    FROM combined_sales
    GROUP BY item_id
),
review_agg AS (
    SELECT pr_item_id AS item_id,
           COUNT(*) AS review_count,
           AVG(pr_rating) AS avg_rating
    FROM product_reviews
    GROUP BY pr_item_id
),
item_stats AS (
    SELECT i.i_item_id,
           i.i_name,
           i.i_category_name,
           i.i_price,
           COALESCE(s.total_quantity, 0) AS total_quantity,
           COALESCE(r.review_count, 0) AS review_count,
           r.avg_rating
    FROM items i
    LEFT JOIN sales_agg s
        ON i.i_item_id = s.item_id
    LEFT JOIN review_agg r
        ON i.i_item_id = r.item_id
),
ranked_items AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY i_category_name ORDER BY total_quantity DESC) AS rn
    FROM item_stats
)
SELECT i_item_id,
       i_name,
       i_category_name,
       i_price,
       total_quantity,
       review_count,
       avg_rating,
       total_quantity * i_price AS total_revenue
FROM ranked_items
WHERE rn <= 5
ORDER BY i_category_name, total_quantity DESC
