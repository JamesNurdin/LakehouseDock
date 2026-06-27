WITH fact_orders AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_quantity,
        od.d_year,
        c.c_region,
        s.s_region AS supplier_region,
        p.p_category
    FROM lineorder lo
    JOIN dim_date od
        ON lo.lo_orderdate = CAST(od.d_datekey AS INTEGER)
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE od.d_year = '1995'
      AND s.s_region = 'ASIA'
      AND p.p_category = 'MFGR#1'
      AND lo.lo_commitdate > lo.lo_orderdate
)
SELECT
    d_year,
    c_region,
    supplier_region,
    p_category,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_quantity) AS total_quantity,
    AVG(lo_discount) AS avg_discount,
    COUNT(DISTINCT lo_suppkey) AS distinct_suppliers
FROM fact_orders
GROUP BY d_year, c_region, supplier_region, p_category
ORDER BY total_revenue DESC
LIMIT 10
