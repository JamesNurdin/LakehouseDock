WITH region_year_revenue AS (
    SELECT
        od.d_year,
        c.c_region,
        SUM(lo.lo_revenue) AS total_revenue,
        AVG(lo.lo_discount) AS avg_discount,
        COUNT(DISTINCT lo.lo_orderkey) AS num_orders
    FROM lineorder lo
    JOIN dim_date od
        ON CAST(od.d_datekey AS INTEGER) = lo.lo_orderdate
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE CAST(od.d_date AS DATE) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
      AND p.p_category = 'MFGR#1'
      AND s.s_region = 'ASIA'
    GROUP BY od.d_year, c.c_region
)
SELECT
    r.d_year,
    r.c_region,
    r.total_revenue,
    r.avg_discount,
    r.num_orders,
    r.total_revenue / SUM(r.total_revenue) OVER (PARTITION BY r.d_year) AS revenue_share
FROM region_year_revenue r
ORDER BY r.total_revenue DESC
