WITH order_commit AS (
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
        od.d_month AS order_month,
        od.d_date AS order_date,
        cd.d_year AS commit_year,
        cd.d_month AS commit_month,
        cd.d_date AS commit_date
    FROM lineorder lo
    JOIN dim_date od
        ON lo.lo_orderdate = CAST(od.d_datekey AS integer)
    JOIN dim_date cd
        ON lo.lo_commitdate = CAST(cd.d_datekey AS integer)
    WHERE CAST(od.d_date AS date) BETWEEN DATE '1995-01-01' AND DATE '1997-12-31'
      AND cd.d_month = '12'
)
SELECT
    order_year,
    order_month,
    commit_month,
    SUM(lo_revenue) AS total_revenue,
    AVG(lo_discount) AS avg_discount,
    COUNT(DISTINCT lo_custkey) AS unique_customers,
    SUM(lo_extendedprice) AS total_extended_price
FROM order_commit
GROUP BY order_year, order_month, commit_month
ORDER BY total_revenue DESC
LIMIT 10
