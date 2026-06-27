WITH orders AS (
    SELECT
        lo_orderkey,
        lo_linenumber,
        lo_custkey,
        lo_partkey,
        lo_suppkey,
        lo_orderdate,
        lo_commitdate,
        lo_shipmode,
        lo_quantity,
        lo_extendedprice,
        lo_ordertotalprice,
        lo_discount,
        lo_revenue,
        lo_supplycost,
        lo_tax,
        lo_orderpriority,
        lo_shippriority,
        CAST(od.d_datekey AS integer) AS od_datekey,
        od.d_date AS od_date,
        od.d_year AS od_year,
        od.d_month AS od_month,
        CAST(cd.d_datekey AS integer) AS cd_datekey,
        cd.d_date AS cd_date,
        cd.d_year AS cd_year,
        cd.d_month AS cd_month
    FROM lineorder
    JOIN dim_date AS od
        ON CAST(od.d_datekey AS integer) = lineorder.lo_orderdate
    JOIN dim_date AS cd
        ON CAST(cd.d_datekey AS integer) = lineorder.lo_commitdate
    WHERE CAST(od.d_date AS date) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
)
SELECT
    od_year,
    od_month,
    cd_year,
    cd_month,
    lo_shipmode,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_extendedprice) AS total_extended_price,
    SUM(lo_quantity) AS total_quantity,
    AVG(lo_discount) AS avg_discount,
    SUM(lo_revenue - lo_supplycost) AS total_profit
FROM orders
GROUP BY od_year, od_month, cd_year, cd_month, lo_shipmode
ORDER BY od_year, od_month, cd_year, cd_month, lo_shipmode
