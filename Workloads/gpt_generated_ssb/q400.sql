WITH order_dates AS (
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
        od.d_year AS order_year,
        od.d_month AS order_month,
        od.d_date AS order_date,
        cd.d_date AS commit_date
    FROM lineorder lo
    JOIN dim_date od
        ON CAST(lo.lo_orderdate AS varchar) = od.d_datekey
    JOIN dim_date cd
        ON CAST(lo.lo_commitdate AS varchar) = cd.d_datekey
)
SELECT
    od.order_year,
    c.c_region,
    p.p_category,
    SUM(od.lo_revenue) AS total_revenue,
    SUM(od.lo_supplycost) AS total_supply_cost,
    SUM(od.lo_revenue - od.lo_supplycost) AS total_profit,
    AVG(od.lo_discount) AS avg_discount,
    AVG(date_diff('day', CAST(od.order_date AS date), CAST(od.commit_date AS date))) AS avg_lead_time_days
FROM order_dates od
JOIN customer c
    ON od.lo_custkey = c.c_custkey
JOIN part p
    ON od.lo_partkey = p.p_partkey
JOIN supplier s
    ON od.lo_suppkey = s.s_suppkey
WHERE CAST(od.order_date AS date) BETWEEN DATE '1995-01-01' AND DATE '1997-12-31'
  AND c.c_region = 'AMERICA'
GROUP BY od.order_year, c.c_region, p.p_category
ORDER BY od.order_year, total_revenue DESC
