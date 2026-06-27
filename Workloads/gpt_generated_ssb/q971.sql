WITH revenue_by_region AS (
    SELECT
        d_order.d_year AS year,
        s.s_region AS supplier_region,
        c.c_region AS customer_region,
        p.p_category AS category,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
        AVG(lo.lo_discount) AS avg_discount
    FROM lineorder lo
    JOIN dim_date d_order
        ON CAST(d_order.d_datekey AS INTEGER) = lo.lo_orderdate
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    WHERE d_order.d_year = '1995'
    GROUP BY d_order.d_year, s.s_region, c.c_region, p.p_category
)
SELECT
    year,
    supplier_region,
    customer_region,
    category,
    total_revenue,
    total_profit,
    avg_discount,
    total_profit / NULLIF(total_revenue, 0) AS profit_margin,
    RANK() OVER (PARTITION BY year, supplier_region ORDER BY total_revenue DESC) AS revenue_rank
FROM revenue_by_region
ORDER BY year, supplier_region, revenue_rank
