WITH order_dates AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_extendedprice,
        lo.lo_quantity,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        d_ord.d_year AS order_year,
        d_ord.d_month AS order_month,
        d_com.d_year AS commit_year
    FROM lineorder lo
    JOIN dim_date d_ord
        ON CAST(d_ord.d_datekey AS integer) = lo.lo_orderdate
    JOIN dim_date d_com
        ON CAST(d_com.d_datekey AS integer) = lo.lo_commitdate
),
agg AS (
    SELECT
        od.order_year,
        c.c_region,
        p.p_category,
        SUM(od.lo_revenue) AS total_revenue,
        SUM(od.lo_supplycost) AS total_supplycost,
        SUM(od.lo_revenue - od.lo_supplycost) AS total_profit,
        COUNT(DISTINCT od.lo_orderkey) AS distinct_orders
    FROM order_dates od
    JOIN customer c
        ON od.lo_custkey = c.c_custkey
    JOIN part p
        ON od.lo_partkey = p.p_partkey
    JOIN supplier s
        ON od.lo_suppkey = s.s_suppkey
    WHERE od.order_year = '1995'
      AND p.p_category = 'MFGR#1'
      AND s.s_region = 'ASIA'
    GROUP BY od.order_year, c.c_region, p.p_category
)
SELECT
    a.order_year,
    a.c_region,
    a.p_category,
    a.total_revenue,
    a.total_supplycost,
    a.total_profit,
    a.distinct_orders,
    ROW_NUMBER() OVER (PARTITION BY a.order_year, a.c_region ORDER BY a.total_profit DESC) AS profit_rank
FROM agg a
ORDER BY a.order_year, a.c_region, profit_rank
