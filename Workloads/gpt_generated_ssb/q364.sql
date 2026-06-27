WITH order_date AS (
    SELECT
        lo_orderkey,
        lo_custkey,
        lo_partkey,
        lo_suppkey,
        lo_quantity,
        lo_extendedprice,
        lo_discount,
        lo_revenue,
        lo_supplycost,
        lo_tax,
        lo_orderdate
    FROM lineorder
),
order_year AS (
    SELECT
        od.lo_orderkey,
        od.lo_custkey,
        od.lo_partkey,
        od.lo_suppkey,
        od.lo_quantity,
        od.lo_extendedprice,
        od.lo_discount,
        od.lo_revenue,
        od.lo_supplycost,
        od.lo_tax,
        d.d_year,
        d.d_date
    FROM order_date od
    JOIN dim_date d
        ON CAST(od.lo_orderdate AS VARCHAR) = d.d_datekey
),
filtered AS (
    SELECT
        oy.lo_custkey,
        oy.lo_partkey,
        oy.lo_suppkey,
        oy.lo_quantity,
        oy.lo_extendedprice,
        oy.lo_discount,
        oy.lo_revenue,
        oy.lo_supplycost,
        oy.lo_tax,
        oy.d_year,
        oy.d_date,
        c.c_region,
        c.c_mktsegment,
        p.p_category,
        p.p_brand1,
        s.s_region AS supplier_region
    FROM order_year oy
    JOIN customer c
        ON oy.lo_custkey = c.c_custkey
    JOIN part p
        ON oy.lo_partkey = p.p_partkey
    JOIN supplier s
        ON oy.lo_suppkey = s.s_suppkey
    WHERE c.c_mktsegment = 'AUTOMOBILE'
      AND p.p_category = 'MFGR#1'
      AND oy.d_year = '1997'
)
SELECT
    f.d_year,
    f.supplier_region,
    SUM(f.lo_revenue) AS total_revenue,
    SUM(f.lo_revenue - f.lo_supplycost) AS total_profit,
    AVG(f.lo_discount) AS avg_discount,
    SUM(f.lo_quantity) AS total_quantity
FROM filtered f
GROUP BY f.d_year, f.supplier_region
ORDER BY f.d_year, f.supplier_region
