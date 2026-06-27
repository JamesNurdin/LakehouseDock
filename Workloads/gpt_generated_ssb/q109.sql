WITH agg AS (
    SELECT
        d.d_year,
        c.c_region,
        p.p_category,
        s.s_nation,
        SUM(lo.lo_extendedprice * (100 - lo.lo_discount) / 100.0) AS revenue,
        SUM(lo.lo_extendedprice - lo.lo_supplycost) AS profit,
        SUM(lo.lo_quantity) AS total_quantity,
        AVG(lo.lo_discount) AS avg_discount,
        COUNT(DISTINCT lo.lo_orderkey) AS order_count
    FROM lineorder lo
    JOIN dim_date d
        ON CAST(lo.lo_orderdate AS VARCHAR) = d.d_datekey
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE d.d_year = '1995'
    GROUP BY d.d_year, c.c_region, p.p_category, s.s_nation
)
SELECT
    agg.d_year,
    agg.c_region,
    agg.p_category,
    agg.s_nation,
    agg.revenue,
    agg.profit,
    agg.total_quantity,
    agg.avg_discount,
    agg.order_count,
    RANK() OVER (PARTITION BY agg.p_category ORDER BY agg.revenue DESC) AS revenue_rank
FROM agg
ORDER BY agg.p_category, revenue_rank
