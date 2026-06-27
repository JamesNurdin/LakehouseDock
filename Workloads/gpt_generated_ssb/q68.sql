WITH revenue_by_year_category AS (
    SELECT
        od.d_year AS order_year,
        p.p_category,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_quantity) AS total_quantity,
        AVG(lo.lo_discount) AS avg_discount,
        COUNT(DISTINCT lo.lo_orderkey) AS num_orders
    FROM lineorder lo
    JOIN dim_date od
        ON CAST(lo.lo_orderdate AS varchar) = od.d_datekey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    WHERE od.d_year = '1995'
    GROUP BY od.d_year, p.p_category
)
SELECT
    order_year,
    p_category,
    total_revenue,
    total_quantity,
    avg_discount,
    num_orders,
    RANK() OVER (PARTITION BY order_year ORDER BY total_revenue DESC) AS revenue_rank
FROM revenue_by_year_category
ORDER BY order_year, revenue_rank
LIMIT 100
