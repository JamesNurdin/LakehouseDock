WITH enriched_sales AS (
    SELECT
        ss.ss_store_id,
        s.s_store_name,
        i.i_category_id,
        i.i_category_name,
        ss.ss_customer_id,
        ss.ss_quantity,
        i.i_price,
        i.i_comp_price,
        ss.ss_quantity * i.i_price AS line_revenue,
        i.i_price - i.i_comp_price AS price_diff
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    JOIN stores s
        ON ss.ss_store_id = s.s_store_id
    JOIN customers c
        ON ss.ss_customer_id = c.c_customer_id
),
agg_sales AS (
    SELECT
        es.ss_store_id,
        es.s_store_name,
        es.i_category_id,
        es.i_category_name,
        SUM(es.line_revenue) AS total_revenue,
        SUM(es.ss_quantity) AS total_quantity,
        AVG(es.price_diff) AS avg_price_diff,
        COUNT(DISTINCT es.ss_customer_id) AS distinct_customers
    FROM enriched_sales es
    GROUP BY
        es.ss_store_id,
        es.s_store_name,
        es.i_category_id,
        es.i_category_name
)
SELECT
    a.ss_store_id,
    a.s_store_name,
    a.i_category_id,
    a.i_category_name,
    a.total_revenue,
    a.total_quantity,
    a.avg_price_diff,
    a.distinct_customers,
    RANK() OVER (PARTITION BY a.ss_store_id ORDER BY a.total_revenue DESC) AS category_revenue_rank
FROM agg_sales a
ORDER BY a.ss_store_id, category_revenue_rank
