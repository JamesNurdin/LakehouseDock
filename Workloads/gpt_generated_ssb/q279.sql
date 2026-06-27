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
        d_order.d_year AS order_year,
        d_order.d_month AS order_month,
        d_order.d_date AS order_date,
        d_commit.d_year AS commit_year,
        d_commit.d_month AS commit_month,
        d_commit.d_date AS commit_date
    FROM lineorder lo
    JOIN dim_date d_order
        ON cast(lo.lo_orderdate AS varchar) = d_order.d_datekey
    JOIN dim_date d_commit
        ON cast(lo.lo_commitdate AS varchar) = d_commit.d_datekey
)
SELECT
    s.s_region,
    od.order_year,
    SUM(od.lo_revenue) AS total_revenue,
    SUM(od.lo_revenue - od.lo_supplycost) AS total_profit,
    AVG(od.lo_discount) AS avg_discount,
    AVG(date_diff('day', date(od.order_date), date(od.commit_date))) AS avg_shipping_delay,
    COUNT(DISTINCT od.lo_orderkey) AS distinct_orders
FROM order_dates od
JOIN supplier s
    ON od.lo_suppkey = s.s_suppkey
JOIN part p
    ON od.lo_partkey = p.p_partkey
WHERE p.p_category = 'MFGR#12'
  AND od.order_year BETWEEN '1993' AND '1995'
GROUP BY s.s_region, od.order_year
ORDER BY s.s_region, od.order_year
