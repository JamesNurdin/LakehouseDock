WITH order_facts AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        lo.lo_quantity,
        c.c_region,
        c.c_nation,
        p.p_category,
        p.p_brand1,
        s.s_region,
        d.d_year
    FROM lineorder lo
    JOIN dim_date d ON lo.lo_orderdate = CAST(d.d_datekey AS INTEGER)
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    JOIN part p ON lo.lo_partkey = p.p_partkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    WHERE d.d_year BETWEEN '1993' AND '1997'
)
SELECT
    c_region,
    s_region,
    p_category,
    d_year,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_supplycost) AS total_supplycost,
    SUM(lo_revenue) - SUM(lo_supplycost) AS profit,
    COUNT(DISTINCT lo_orderkey) AS order_count
FROM order_facts
GROUP BY c_region, s_region, p_category, d_year
ORDER BY profit DESC
LIMIT 20
