WITH lo_with_dates AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_linenumber,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_shipmode,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_ordertotalprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        od.d_yearmonth AS order_yearmonth,
        od.d_year AS order_year,
        od.d_date AS order_date,
        cd.d_date AS commit_date
    FROM lineorder AS lo
    JOIN dim_date AS od
        ON CAST(od.d_datekey AS integer) = lo.lo_orderdate
    JOIN dim_date AS cd
        ON CAST(cd.d_datekey AS integer) = lo.lo_commitdate
    WHERE od.d_year = '1995'
)
SELECT
    order_yearmonth,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_quantity) AS total_quantity,
    AVG(lo_discount) AS avg_discount,
    AVG(date_diff('day', CAST(order_date AS date), CAST(commit_date AS date))) AS avg_lead_time_days
FROM lo_with_dates
GROUP BY order_yearmonth
ORDER BY order_yearmonth
