WITH profit_by_supplier AS (
    SELECT
        d.d_year,
        c.c_region,
        s.s_name,
        SUM(lo.lo_revenue - lo.lo_supplycost) AS profit,
        SUM(lo.lo_revenue) AS revenue,
        COUNT(DISTINCT lo.lo_orderkey) AS order_cnt
    FROM lineorder lo
    JOIN dim_date d
        ON lo.lo_orderdate = CAST(d.d_datekey AS integer)
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    WHERE d.d_year >= '1993' AND d.d_year <= '1995'
      AND p.p_category = 'MFGR#1'
    GROUP BY d.d_year, c.c_region, s.s_name
)
SELECT
    d_year,
    c_region,
    s_name,
    profit,
    revenue,
    order_cnt,
    profit_rank
FROM (
    SELECT
        d_year,
        c_region,
        s_name,
        profit,
        revenue,
        order_cnt,
        ROW_NUMBER() OVER (PARTITION BY c_region, d_year ORDER BY profit DESC) AS profit_rank
    FROM profit_by_supplier
) t
WHERE profit_rank <= 5
ORDER BY c_region, d_year, profit_rank
