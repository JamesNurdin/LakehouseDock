WITH lo_joined AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_suppkey,
        lo.lo_partkey,
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_extendedprice,
        lo.lo_ordertotalprice,
        lo.lo_quantity,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        lo.lo_shipmode,
        c.c_region AS c_region,
        s.s_region AS s_region,
        p.p_category,
        p.p_brand1,
        od.d_year AS order_year,
        cd.d_year AS commit_year
    FROM lineorder lo
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    JOIN part p ON lo.lo_partkey = p.p_partkey
    JOIN dim_date od ON CAST(lo.lo_orderdate AS VARCHAR) = od.d_datekey
    JOIN dim_date cd ON CAST(lo.lo_commitdate AS VARCHAR) = cd.d_datekey
    WHERE od.d_year BETWEEN '1995' AND '1997'
      AND p.p_category = 'MFGR#12'
)
SELECT
    order_year,
    c_region AS customer_region,
    s_region AS supplier_region,
    p_category,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_supplycost) AS total_supplycost,
    SUM(lo_revenue - lo_supplycost) AS profit,
    AVG(lo_discount) AS avg_discount,
    COUNT(DISTINCT lo_orderkey) AS order_count
FROM lo_joined
GROUP BY
    order_year,
    c_region,
    s_region,
    p_category
ORDER BY total_revenue DESC
LIMIT 100
