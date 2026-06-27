WITH filtered_orders AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_ordertotalprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        lo.lo_shipmode,
        od.d_year,
        od.d_month,
        od.d_date,
        cd.d_date AS commit_date,
        cust.c_region,
        cust.c_nation,
        part.p_category,
        part.p_brand1,
        supp.s_region AS supplier_region
    FROM lineorder lo
    JOIN dim_date od
        ON CAST(od.d_datekey AS integer) = lo.lo_orderdate
    JOIN dim_date cd
        ON CAST(cd.d_datekey AS integer) = lo.lo_commitdate
    JOIN customer cust
        ON lo.lo_custkey = cust.c_custkey
    JOIN part
        ON lo.lo_partkey = part.p_partkey
    JOIN supplier supp
        ON lo.lo_suppkey = supp.s_suppkey
    WHERE lo.lo_shipmode = 'AIR'
      AND od.d_year = '1995'
      AND od.d_month = '03'
)
SELECT
    d_year,
    d_month,
    c_region,
    p_category,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_supplycost) AS total_supply_cost,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    AVG(lo_discount) AS avg_discount,
    COUNT(DISTINCT lo_orderkey) AS distinct_orders
FROM (
    SELECT
        lo_orderkey,
        lo_revenue,
        lo_supplycost,
        lo_discount,
        d_year,
        d_month,
        c_region,
        p_category
    FROM filtered_orders
) AS f
GROUP BY
    d_year,
    d_month,
    c_region,
    p_category
ORDER BY
    total_revenue DESC
LIMIT 100
