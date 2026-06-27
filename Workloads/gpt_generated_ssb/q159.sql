WITH lo_joined AS (
    SELECT
        od.d_year AS order_year,
        cd.d_year AS commit_year,
        c.c_region AS customer_region,
        s.s_region AS supplier_region,
        p.p_category AS part_category,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_quantity,
        lo.lo_shipmode,
        lo.lo_orderpriority
    FROM lineorder lo
    JOIN dim_date od
        ON CAST(od.d_datekey AS integer) = lo.lo_orderdate
    JOIN dim_date cd
        ON CAST(cd.d_datekey AS integer) = lo.lo_commitdate
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE p.p_category = 'MFGR#1'
      AND c.c_region = 'ASIA'
      AND s.s_region = 'ASIA'
      AND od.d_year = '1995'
      AND lo.lo_shipmode = 'AIR'
)
SELECT
    order_year,
    customer_region,
    part_category,
    SUM(lo_extendedprice * (1 - lo_discount / 100.0)) AS total_sales,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    COUNT(*) AS order_count
FROM lo_joined
GROUP BY order_year, customer_region, part_category
ORDER BY total_sales DESC
LIMIT 10
