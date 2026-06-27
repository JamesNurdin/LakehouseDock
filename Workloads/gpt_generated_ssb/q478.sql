WITH order_data AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_revenue,
        lo.lo_discount,
        d_order.d_year AS order_year,
        p.p_category
    FROM lineorder lo
    JOIN dim_date d_order
        ON CAST(d_order.d_datekey AS INTEGER) = lo.lo_orderdate
    JOIN dim_date d_commit
        ON CAST(d_commit.d_datekey AS INTEGER) = lo.lo_commitdate
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    WHERE d_order.d_year = '1998'
)
SELECT
    order_year,
    p_category,
    total_revenue,
    avg_discount,
    num_orders,
    total_revenue * 100.0 / SUM(total_revenue) OVER (PARTITION BY order_year) AS revenue_pct
FROM (
    SELECT
        order_year,
        p_category,
        SUM(lo_revenue) AS total_revenue,
        AVG(lo_discount) AS avg_discount,
        COUNT(DISTINCT lo_orderkey) AS num_orders
    FROM order_data
    GROUP BY order_year, p_category
) agg
ORDER BY total_revenue DESC
LIMIT 10
