WITH order_dates AS (
    SELECT d_datekey, d_year, d_date
    FROM dim_date
    WHERE d_year = '1996'
),
commit_dates AS (
    SELECT d_datekey, d_year
    FROM dim_date
    WHERE d_year = '1995'
)
SELECT
    od.d_year AS order_year,
    c.c_region,
    p.p_category,
    s.s_nation,
    SUM(lo.lo_extendedprice) AS total_extended_price,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
    AVG(lo.lo_discount) AS avg_discount,
    COUNT(DISTINCT lo.lo_orderkey) AS distinct_orders
FROM lineorder lo
JOIN order_dates od
    ON lo.lo_orderdate = CAST(od.d_datekey AS integer)
JOIN commit_dates cd
    ON lo.lo_commitdate = CAST(cd.d_datekey AS integer)
JOIN customer c
    ON lo.lo_custkey = c.c_custkey
JOIN part p
    ON lo.lo_partkey = p.p_partkey
JOIN supplier s
    ON lo.lo_suppkey = s.s_suppkey
GROUP BY od.d_year, c.c_region, p.p_category, s.s_nation
ORDER BY od.d_year, total_revenue DESC
