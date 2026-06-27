WITH store_sales_detail AS (
    SELECT
        ss.ss_store_id,
        ss.ss_item_id,
        ss.ss_quantity
    FROM store_sales ss
),
review_agg AS (
    SELECT
        pr_item_id,
        AVG(pr_rating) AS avg_rating
    FROM product_reviews
    GROUP BY pr_item_id
),
store_category_sales AS (
    SELECT
        s.s_store_name,
        i.i_category_name,
        SUM(ssd.ss_quantity) AS total_quantity,
        COUNT(DISTINCT ssd.ss_item_id) AS distinct_items_sold,
        AVG(r.avg_rating) AS avg_item_rating
    FROM store_sales_detail ssd
    JOIN stores s
        ON s.s_store_id = ssd.ss_store_id
    JOIN items i
        ON i.i_item_id = ssd.ss_item_id
    LEFT JOIN review_agg r
        ON r.pr_item_id = i.i_item_id
    GROUP BY s.s_store_name, i.i_category_name
)
SELECT
    scs.s_store_name,
    scs.i_category_name,
    scs.total_quantity,
    scs.distinct_items_sold,
    scs.avg_item_rating,
    ROW_NUMBER() OVER (PARTITION BY scs.s_store_name ORDER BY scs.total_quantity DESC) AS category_rank
FROM store_category_sales scs
WHERE scs.total_quantity > 0
ORDER BY scs.s_store_name, category_rank
LIMIT 50
