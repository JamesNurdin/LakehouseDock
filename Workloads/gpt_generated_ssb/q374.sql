WITH order_data AS (
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
        lo.lo_supplycost
    FROM lineorder lo
),
joined AS (
    SELECT
        od.lo_orderkey,
        od.lo_quantity,
        od.lo_extendedprice,
        od.lo_discount,
        od.lo_revenue,
        od.lo_supplycost,
        dd.d_year,
        dd.d_date,
        p.p_category,
        p.p_brand1,
        s.s_nation,
        s.s_region,
        c.c_region AS customer_region,
        c.c_mktsegment AS customer_mktsegment
    FROM order_data od
    JOIN dim_date dd ON CAST(dd.d_datekey AS integer) = od.lo_orderdate
    JOIN part p ON od.lo_partkey = p.p_partkey
    JOIN supplier s ON od.lo_suppkey = s.s_suppkey
    JOIN customer c ON od.lo_custkey = c.c_custkey
    WHERE CAST(dd.d_date AS DATE) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
      AND p.p_category = 'MFGR#12'
      AND s.s_region = 'ASIA'
)
SELECT
    d_year,
    s_nation,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_quantity) AS total_quantity,
    AVG(lo_discount) AS avg_discount
FROM joined
GROUP BY d_year, s_nation
ORDER BY total_revenue DESC
LIMIT 10
