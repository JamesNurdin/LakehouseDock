WITH order_commit AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_linenumber,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
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
        cd.d_date AS commit_date
    FROM lineorder lo
    JOIN dim_date od
      ON CAST(lo.lo_orderdate AS varchar) = od.d_datekey
    JOIN dim_date cd
      ON CAST(lo.lo_commitdate AS varchar) = cd.d_datekey
    WHERE od.d_date >= '1992-01-01'
      AND od.d_date < '1995-01-01'
)
SELECT
    order_year,
    order_month,
    lo_shipmode,
    COUNT(*) AS order_count,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    AVG(lo_discount) AS avg_discount,
    AVG(date_diff('day', CAST(order_date AS date), CAST(commit_date AS date))) AS avg_lead_days
FROM order_commit
GROUP BY order_year, order_month, lo_shipmode
ORDER BY order_year, order_month, lo_shipmode
