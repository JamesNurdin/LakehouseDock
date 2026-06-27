WITH filtered_orders AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        lo.lo_shipmode,
        d.d_year,
        d.d_month,
        c.c_region,
        p.p_category,
        s.s_nation
    FROM lineorder lo
    JOIN dim_date d
        ON CAST(d.d_datekey AS integer) = lo.lo_orderdate
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE d.d_year = '1995'
      AND lo.lo_shipmode = 'AIR'
)
SELECT
    fo.d_year,
    fo.c_region,
    fo.p_category,
    SUM(fo.lo_revenue) AS total_revenue,
    SUM(fo.lo_revenue - fo.lo_supplycost) AS total_profit,
    COUNT(DISTINCT fo.lo_orderkey) AS order_count
FROM filtered_orders fo
GROUP BY fo.d_year, fo.c_region, fo.p_category
ORDER BY total_revenue DESC
LIMIT 20
