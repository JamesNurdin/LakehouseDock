WITH order_details AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        c.c_region,
        c.c_name,
        c.c_city,
        p.p_category,
        s.s_region,
        d.d_year
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
      AND s.s_region = 'ASIA'
      AND d.d_year = '1998'
)
SELECT
    c_region,
    d_year,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_extendedprice) AS total_extendedprice,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    AVG(lo_discount) AS avg_discount
FROM order_details
GROUP BY c_region, d_year
ORDER BY total_revenue DESC
