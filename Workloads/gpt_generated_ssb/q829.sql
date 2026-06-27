WITH order_data AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_quantity,
        lo.lo_orderdate,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        d.d_year,
        c.c_region,
        s.s_region,
        p.p_category
    FROM lineorder lo
    JOIN dim_date d
        ON CAST(d.d_datekey AS INTEGER) = lo.lo_orderdate
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE d.d_year = '1998'
      AND c.c_region = 'ASIA'
)
SELECT
    d_year,
    c_region,
    s_region,
    p_category,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    SUM(lo_quantity) AS total_quantity
FROM order_data
GROUP BY d_year, c_region, s_region, p_category
ORDER BY total_revenue DESC
LIMIT 10
