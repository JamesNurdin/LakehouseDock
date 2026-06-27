WITH lo_dates AS (
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
        od.d_year AS order_year,
        od.d_date AS order_date,
        cd.d_year AS commit_year,
        cd.d_date AS commit_date
    FROM lineorder lo
    JOIN dim_date od
      ON CAST(od.d_datekey AS integer) = lo.lo_orderdate
    JOIN dim_date cd
      ON CAST(cd.d_datekey AS integer) = lo.lo_commitdate
)
SELECT
    lo_dates.order_year,
    customer.c_region,
    part.p_category,
    SUM(lo_dates.lo_revenue) AS total_revenue,
    SUM(lo_dates.lo_revenue - lo_dates.lo_supplycost) AS total_profit,
    AVG(lo_dates.lo_discount) AS avg_discount,
    COUNT(DISTINCT lo_dates.lo_orderkey) AS distinct_orders,
    SUM(lo_dates.lo_quantity) AS total_quantity
FROM lo_dates
JOIN customer
  ON lo_dates.lo_custkey = customer.c_custkey
JOIN part
  ON lo_dates.lo_partkey = part.p_partkey
JOIN supplier
  ON lo_dates.lo_suppkey = supplier.s_suppkey
WHERE lo_dates.order_year BETWEEN '1993' AND '1995'
GROUP BY lo_dates.order_year, customer.c_region, part.p_category
ORDER BY total_revenue DESC
LIMIT 100
