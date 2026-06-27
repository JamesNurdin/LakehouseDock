WITH order_info AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        od.d_year,
        od.d_month,
        od.d_date,
        c.c_region,
        c.c_nation,
        p.p_category,
        p.p_brand1,
        s.s_region AS supplier_region,
        s.s_nation AS supplier_nation
    FROM lineorder lo
    JOIN dim_date od
        ON CAST(lo.lo_orderdate AS varchar) = od.d_datekey
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE od.d_year = '1995'
)

SELECT
    c_region,
    d_year,
    p_category,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_extendedprice - lo_supplycost) AS profit,
    COUNT(DISTINCT lo_orderkey) AS num_orders
FROM order_info
GROUP BY c_region, d_year, p_category
ORDER BY total_revenue DESC
LIMIT 10
