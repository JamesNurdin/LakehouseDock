WITH revenue_by_category AS (
    SELECT
        ss.ss_store_id,
        i.i_category_name,
        SUM(i.i_price * ss.ss_quantity) AS category_revenue,
        SUM(ss.ss_quantity) AS category_units,
        AVG(i.i_price) AS avg_price,
        AVG(i.i_comp_price - i.i_price) AS avg_discount,
        COUNT(DISTINCT ss.ss_customer_id) AS distinct_customers
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    JOIN customers c
        ON ss.ss_customer_id = c.c_customer_id
    WHERE i.i_price > 0
    GROUP BY ss.ss_store_id, i.i_category_name
),
ranked_categories AS (
    SELECT
        r.ss_store_id,
        r.i_category_name,
        r.category_revenue,
        r.category_units,
        r.avg_price,
        r.avg_discount,
        r.distinct_customers,
        ROW_NUMBER() OVER (PARTITION BY r.ss_store_id ORDER BY r.category_revenue DESC) AS category_rank
    FROM revenue_by_category r
)
SELECT
    s.s_store_name,
    rc.i_category_name,
    rc.category_revenue,
    rc.category_units,
    rc.avg_price,
    rc.avg_discount,
    rc.distinct_customers,
    rc.category_rank
FROM ranked_categories rc
JOIN stores s
    ON rc.ss_store_id = s.s_store_id
WHERE rc.category_rank <= 3
ORDER BY s.s_store_name, rc.category_rank
