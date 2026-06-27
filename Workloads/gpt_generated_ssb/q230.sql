WITH order_dates AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_linenumber,
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
        d.d_year,
        d.d_month,
        d.d_date
    FROM lineorder lo
    JOIN dim_date d
      ON CAST(d.d_datekey AS integer) = lo.lo_orderdate
), supplier_orders AS (
    SELECT
        o.*, 
        s.s_name,
        s.s_city,
        s.s_nation,
        s.s_region
    FROM order_dates o
    JOIN supplier s
      ON o.lo_suppkey = s.s_suppkey
)
SELECT
    s_region,
    d_year,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_extendedprice) AS total_extendedprice,
    AVG(lo_discount) AS avg_discount,
    COUNT(DISTINCT lo_orderkey) AS distinct_orders
FROM supplier_orders
WHERE d_year = '1995'
GROUP BY s_region, d_year
ORDER BY total_revenue DESC
