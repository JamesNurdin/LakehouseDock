WITH base_sales AS (
    SELECT
        ss.ss_store_id,
        s.s_store_name,
        i.i_category_id,
        i.i_category_name,
        ss.ss_quantity,
        i.i_price,
        ss.ss_customer_id,
        ss.ss_item_id
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    WHERE ss.ss_quantity > 0
),
base_reviews AS (
    SELECT
        pr.pr_item_id,
        pr.pr_rating
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    WHERE pr.pr_rating >= 4
)

SELECT
    bs.s_store_name,
    bs.i_category_name,
    SUM(bs.ss_quantity) AS total_quantity,
    SUM(bs.ss_quantity * bs.i_price) AS total_revenue,
    AVG(br.pr_rating) AS avg_rating,
    COUNT(DISTINCT bs.ss_customer_id) AS distinct_customers
FROM base_sales bs
JOIN base_reviews br
    ON bs.ss_item_id = br.pr_item_id
GROUP BY bs.s_store_name, bs.i_category_name
ORDER BY total_revenue DESC
LIMIT 10
