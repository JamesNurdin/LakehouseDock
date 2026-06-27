WITH order_agg AS (
    SELECT
        d.d_year AS order_year,
        c.c_mktsegment,
        p.p_brand1,
        s.s_region,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
        AVG(lo.lo_discount) AS avg_discount,
        COUNT(DISTINCT lo.lo_orderkey) AS order_cnt
    FROM lineorder lo
    JOIN dim_date d
        ON lo.lo_orderdate = CAST(d.d_datekey AS integer)
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE p.p_category = 'MFGR#12'
      AND lo.lo_discount > 0
    GROUP BY d.d_year, c.c_mktsegment, p.p_brand1, s.s_region
)
SELECT
    order_year,
    c_mktsegment,
    p_brand1,
    s_region,
    total_revenue,
    total_profit,
    total_profit / NULLIF(total_revenue, 0) AS profit_margin,
    avg_discount,
    order_cnt
FROM order_agg
ORDER BY order_year, total_revenue DESC
