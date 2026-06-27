WITH item_ratings AS (
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
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(i.i_price * ss.ss_quantity) AS total_revenue,
        AVG(ir.avg_rating) AS avg_item_rating
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    JOIN stores s
        ON ss.ss_store_id = s.s_store_id
    LEFT JOIN item_ratings ir
        ON i.i_item_id = ir.pr_item_id
    GROUP BY s.s_store_name, i.i_category_name
)
SELECT
    sc.s_store_name,
    sc.i_category_name,
    sc.total_quantity,
    sc.total_revenue,
    sc.avg_item_rating,
    ROW_NUMBER() OVER (ORDER BY sc.total_revenue DESC) AS revenue_rank
FROM store_category_sales sc
ORDER BY sc.total_revenue DESC
