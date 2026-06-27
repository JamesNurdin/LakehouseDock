WITH order_details AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        lo.lo_tax,
        lo.lo_shipmode,
        p.p_category,
        p.p_brand1,
        s.s_region AS supplier_region,
        c.c_region AS customer_region,
        od.d_year AS order_year,
        cd.d_year AS commit_year
    FROM lineorder lo
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN dim_date od
        ON CAST(lo.lo_orderdate AS varchar) = od.d_datekey
    JOIN dim_date cd
        ON CAST(lo.lo_commitdate AS varchar) = cd.d_datekey
    WHERE od.d_year = '1995'
      AND p.p_category = 'MFGR#1'
)
SELECT
    order_year,
    supplier_region,
    SUM(lo_extendedprice) AS total_extended_price,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_extendedprice - lo_supplycost) AS total_profit,
    COUNT(DISTINCT lo_orderkey) AS num_orders
FROM order_details
GROUP BY order_year, supplier_region
ORDER BY total_revenue DESC
LIMIT 10
