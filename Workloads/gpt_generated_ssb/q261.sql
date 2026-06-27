WITH revenue_by_region_year AS (
    SELECT
        d_order.d_year AS order_year,
        s.s_region,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_supplycost) AS total_supplycost,
        SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
        AVG(lo.lo_discount) AS avg_discount,
        COUNT(DISTINCT lo.lo_orderkey) AS distinct_orders
    FROM lineorder lo
    JOIN dim_date d_order
        ON CAST(lo.lo_orderdate AS varchar) = d_order.d_datekey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE d_order.d_year = '1995'
      AND p.p_category = 'MFGR#12'
    GROUP BY d_order.d_year, s.s_region
)
SELECT
    order_year,
    s_region,
    total_revenue,
    total_supplycost,
    total_profit,
    avg_discount,
    distinct_orders,
    RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
FROM revenue_by_region_year
ORDER BY order_year DESC, total_revenue DESC
