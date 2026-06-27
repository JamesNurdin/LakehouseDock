WITH filtered_orders AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        lo.lo_suppkey,
        od.d_year,
        c.c_region,
        p.p_category,
        s.s_region AS supplier_region
    FROM lineorder lo
    JOIN dim_date od
        ON CAST(lo.lo_orderdate AS varchar) = od.d_datekey
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE od.d_year IN ('1995', '1996', '1997')
      AND p.p_category = 'MFGR#12'
      AND s.s_region = 'ASIA'
)
SELECT
    d_year,
    c_region,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    AVG(lo_discount) AS avg_discount,
    COUNT(DISTINCT lo_orderkey) AS order_count,
    COUNT(DISTINCT lo_suppkey) AS supplier_count
FROM filtered_orders
GROUP BY d_year, c_region
ORDER BY total_revenue DESC
