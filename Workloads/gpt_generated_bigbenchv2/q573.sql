WITH item_ratings AS (
    SELECT
        i.i_item_id,
        AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    JOIN items i
        ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
store_customer_sales AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        c.c_customer_id,
        c.c_name,
        SUM(ss.ss_quantity * i.i_price) AS revenue,
        COUNT(DISTINCT ss.ss_item_id) AS distinct_items,
        SUM(ss.ss_quantity) AS total_quantity,
        AVG(ir.avg_rating) AS avg_item_rating
    FROM store_sales ss
    JOIN stores s
        ON ss.ss_store_id = s.s_store_id
    JOIN customers c
        ON ss.ss_customer_id = c.c_customer_id
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    LEFT JOIN item_ratings ir
        ON i.i_item_id = ir.i_item_id
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        c.c_customer_id,
        c.c_name
)
SELECT
    scs.s_store_name,
    scs.c_name,
    scs.revenue,
    scs.total_quantity,
    scs.distinct_items,
    scs.avg_item_rating,
    RANK() OVER (PARTITION BY scs.s_store_name ORDER BY scs.revenue DESC) AS revenue_rank
FROM store_customer_sales scs
ORDER BY scs.s_store_name, revenue_rank
