WITH order_summary AS (
    SELECT
        d.d_year,
        c.c_region,
        s.s_nation,
        p.p_category,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_supplycost) AS total_supplycost,
        SUM(lo.lo_revenue) - SUM(lo.lo_supplycost) AS total_profit,
        AVG(lo.lo_discount) AS avg_discount
    FROM lineorder lo
    JOIN dim_date d
        ON lo.lo_orderdate = CAST(d.d_datekey AS INTEGER)
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    WHERE d.d_year = '1994'
      AND p.p_category = 'MFGR#12'
      AND s.s_nation = 'UNITED STATES'
    GROUP BY d.d_year, c.c_region, s.s_nation, p.p_category
)
SELECT
    d_year,
    c_region,
    s_nation,
    p_category,
    total_revenue,
    total_supplycost,
    total_profit,
    avg_discount,
    ROW_NUMBER() OVER (ORDER BY total_revenue DESC) AS revenue_rank
FROM order_summary
ORDER BY total_revenue DESC
LIMIT 100
