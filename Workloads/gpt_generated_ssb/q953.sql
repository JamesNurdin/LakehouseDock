WITH orders_1994 AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_quantity,
        d.d_year,
        d.d_month,
        d.d_date
    FROM lineorder lo
    JOIN dim_date d
        ON CAST(lo.lo_orderdate AS VARCHAR) = d.d_datekey
    WHERE d.d_year = '1994'
),
agg AS (
    SELECT
        s.s_region,
        p.p_category,
        SUM(o.lo_revenue) AS total_revenue,
        SUM(o.lo_revenue - o.lo_supplycost) AS total_profit,
        COUNT(DISTINCT o.lo_orderkey) AS order_cnt
    FROM orders_1994 o
    JOIN supplier s
        ON o.lo_suppkey = s.s_suppkey
    JOIN part p
        ON o.lo_partkey = p.p_partkey
    GROUP BY s.s_region, p.p_category
)
SELECT
    a.s_region,
    a.p_category,
    a.total_revenue,
    a.total_profit,
    a.order_cnt,
    RANK() OVER (PARTITION BY a.s_region ORDER BY a.total_revenue DESC) AS revenue_rank
FROM agg a
ORDER BY a.s_region, revenue_rank
LIMIT 50
