WITH orders AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_extendedprice,
        lo.lo_discount,
        d.d_year,
        d.d_date,
        c.c_name,
        c.c_region,
        p.p_category,
        s.s_name,
        s.s_region
    FROM lineorder lo
    JOIN dim_date d
        ON CAST(lo.lo_orderdate AS VARCHAR) = d.d_datekey
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE CAST(d.d_date AS DATE) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
),
aggregated AS (
    SELECT
        o.d_year,
        o.c_name,
        SUM(o.lo_extendedprice * (1 - o.lo_discount / 100.0)) AS revenue
    FROM orders o
    GROUP BY o.d_year, o.c_name
    HAVING SUM(o.lo_extendedprice * (1 - o.lo_discount / 100.0)) > 0
)
SELECT
    a.d_year,
    a.c_name,
    a.revenue,
    ROW_NUMBER() OVER (PARTITION BY a.d_year ORDER BY a.revenue DESC) AS revenue_rank
FROM aggregated a
ORDER BY a.d_year, revenue_rank
LIMIT 20
