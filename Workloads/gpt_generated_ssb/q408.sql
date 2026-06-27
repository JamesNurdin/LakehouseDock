WITH order_details AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_linenumber,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_shipmode,
        cust.c_region,
        cust.c_nation,
        part.p_category,
        part.p_brand1,
        supp.s_region,
        od.d_year AS order_year,
        cd.d_year AS commit_year
    FROM lineorder lo
    JOIN customer cust
        ON lo.lo_custkey = cust.c_custkey
    JOIN part part
        ON lo.lo_partkey = part.p_partkey
    JOIN supplier supp
        ON lo.lo_suppkey = supp.s_suppkey
    JOIN dim_date od
        ON lo.lo_orderdate = CAST(od.d_datekey AS integer)
    JOIN dim_date cd
        ON lo.lo_commitdate = CAST(cd.d_datekey AS integer)
    WHERE od.d_year = '1995'
      AND lo.lo_shipmode = 'AIR'
)
SELECT
    order_year,
    c_region,
    p_category,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_supplycost) AS total_supply_cost,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    SUM(lo_quantity) AS total_quantity,
    AVG(lo_discount) AS avg_discount,
    COUNT(DISTINCT lo_orderkey) AS distinct_orders
FROM order_details
GROUP BY order_year, c_region, p_category
HAVING SUM(lo_revenue) > 1000000
ORDER BY total_revenue DESC
LIMIT 20
