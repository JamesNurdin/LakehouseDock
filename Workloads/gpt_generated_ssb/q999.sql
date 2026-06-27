WITH order_date AS (
    SELECT d_datekey, d_date, d_year
    FROM dim_date
),
commit_date AS (
    SELECT d_datekey, d_date
    FROM dim_date
)
SELECT
    od.d_year AS order_year,
    c.c_region,
    s.s_nation,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_supplycost) AS total_supply_cost,
    SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
    (SUM(lo.lo_revenue - lo.lo_supplycost) / NULLIF(SUM(lo.lo_revenue), 0)) AS profit_margin,
    AVG(lo.lo_discount) AS avg_discount,
    AVG(date_diff('day', CAST(od.d_date AS date), CAST(cd.d_date AS date))) AS avg_lead_time,
    COUNT(DISTINCT lo.lo_orderkey) AS num_orders
FROM lineorder lo
JOIN order_date od
    ON CAST(lo.lo_orderdate AS varchar) = od.d_datekey
JOIN commit_date cd
    ON CAST(lo.lo_commitdate AS varchar) = cd.d_datekey
JOIN customer c
    ON lo.lo_custkey = c.c_custkey
JOIN supplier s
    ON lo.lo_suppkey = s.s_suppkey
WHERE od.d_year = '1995'
  AND c.c_mktsegment = 'AUTOMOBILE'
GROUP BY od.d_year, c.c_region, s.s_nation
ORDER BY total_revenue DESC
LIMIT 10
