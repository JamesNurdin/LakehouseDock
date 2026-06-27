WITH order_summary AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        d.d_year,
        c.c_region,
        p.p_category,
        s.s_nation
    FROM lineorder lo
    JOIN dim_date d
        ON CAST(lo.lo_orderdate AS VARCHAR) = d.d_datekey
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE d.d_year >= '1992'
      AND d.d_year <= '1997'
),
agg AS (
    SELECT
        d_year,
        c_region,
        p_category,
        s_nation,
        SUM(lo_revenue) AS total_revenue,
        SUM(lo_revenue - lo_supplycost) AS total_profit,
        AVG(lo_discount) AS avg_discount,
        COUNT(DISTINCT lo_orderkey) AS order_cnt
    FROM order_summary
    GROUP BY d_year, c_region, p_category, s_nation
)
SELECT
    agg.d_year,
    agg.c_region,
    agg.p_category,
    agg.s_nation,
    agg.total_revenue,
    agg.total_profit,
    agg.avg_discount,
    agg.order_cnt,
    RANK() OVER (PARTITION BY agg.d_year ORDER BY agg.total_revenue DESC) AS revenue_rank
FROM agg
ORDER BY agg.d_year, revenue_rank
LIMIT 20
