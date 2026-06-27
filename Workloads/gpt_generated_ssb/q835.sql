WITH order_dates AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        od.d_year AS order_year,
        cd.d_year AS commit_year
    FROM lineorder lo
    JOIN dim_date od ON CAST(od.d_datekey AS integer) = lo.lo_orderdate
    JOIN dim_date cd ON CAST(cd.d_datekey AS integer) = lo.lo_commitdate
),
grouped AS (
    SELECT
        od.order_year,
        s.s_region,
        p.p_category,
        SUM(od.lo_revenue) AS total_revenue,
        SUM(od.lo_revenue - od.lo_supplycost) AS total_profit,
        AVG(od.lo_discount) AS avg_discount,
        COUNT(DISTINCT od.lo_orderkey) AS distinct_orders
    FROM order_dates od
    JOIN customer c ON od.lo_custkey = c.c_custkey
    JOIN supplier s ON od.lo_suppkey = s.s_suppkey
    JOIN part p ON od.lo_partkey = p.p_partkey
    WHERE od.lo_discount > 5
      AND od.order_year = '1995'
    GROUP BY od.order_year, s.s_region, p.p_category
)
SELECT
    g.order_year,
    g.s_region,
    g.p_category,
    g.total_revenue,
    g.total_profit,
    g.avg_discount,
    g.distinct_orders,
    RANK() OVER (PARTITION BY g.order_year ORDER BY g.total_revenue DESC) AS revenue_rank
FROM grouped g
ORDER BY g.order_year, revenue_rank, g.total_revenue DESC
