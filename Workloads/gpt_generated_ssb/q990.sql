WITH order_agg AS (
    SELECT
        c.c_region AS c_region,
        d.d_year AS d_year,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_supplycost,
        lo.lo_quantity,
        lo.lo_orderkey
    FROM lineorder lo
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    JOIN part p ON lo.lo_partkey = p.p_partkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    JOIN dim_date d ON CAST(d.d_datekey AS integer) = lo.lo_orderdate
    WHERE CAST(d.d_date AS date) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
)
SELECT
    c_region,
    d_year,
    SUM(lo_extendedprice * (1 - lo_discount / 100.0)) AS revenue,
    SUM(lo_supplycost * lo_quantity) AS supply_cost,
    SUM(lo_extendedprice * (1 - lo_discount / 100.0)) - SUM(lo_supplycost * lo_quantity) AS profit,
    AVG(lo_discount) AS avg_discount,
    COUNT(DISTINCT lo_orderkey) AS order_cnt
FROM order_agg
GROUP BY c_region, d_year
ORDER BY revenue DESC
