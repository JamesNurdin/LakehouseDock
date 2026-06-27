WITH order_dates AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_linenumber,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_orderpriority,
        lo.lo_shippriority,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_ordertotalprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        lo.lo_shipmode,
        d_order.d_year AS order_year,
        d_order.d_date AS order_date,
        d_commit.d_year AS commit_year,
        d_commit.d_date AS commit_date
    FROM lineorder lo
    JOIN dim_date d_order
      ON lo.lo_orderdate = CAST(d_order.d_datekey AS INTEGER)
    JOIN dim_date d_commit
      ON lo.lo_commitdate = CAST(d_commit.d_datekey AS INTEGER)
)
SELECT
    od.order_year,
    p.p_category,
    od.lo_shipmode,
    SUM(od.lo_revenue) AS total_revenue,
    AVG(od.lo_discount) AS avg_discount,
    COUNT(DISTINCT od.lo_orderkey) AS distinct_orders
FROM order_dates od
JOIN part p
  ON od.lo_partkey = p.p_partkey
WHERE od.order_date BETWEEN '1995-01-01' AND '1995-12-31'
GROUP BY od.order_year, p.p_category, od.lo_shipmode
ORDER BY od.order_year, total_revenue DESC
