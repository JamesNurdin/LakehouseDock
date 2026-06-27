SELECT
    od.d_year AS order_year,
    c.c_mktsegment,
    p.p_category,
    s.s_region,
    sum(lo.lo_revenue) AS total_revenue,
    sum(lo.lo_supplycost) AS total_supplycost,
    sum(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
    avg(lo.lo_discount) AS avg_discount,
    count(distinct lo.lo_orderkey) AS order_count,
    avg(date_diff('day', cast(od.d_date AS date), cast(cd.d_date AS date))) AS avg_lead_days
FROM lineorder lo
JOIN dim_date od
    ON cast(lo.lo_orderdate AS varchar) = od.d_datekey
JOIN dim_date cd
    ON cast(lo.lo_commitdate AS varchar) = cd.d_datekey
JOIN customer c
    ON lo.lo_custkey = c.c_custkey
JOIN part p
    ON lo.lo_partkey = p.p_partkey
JOIN supplier s
    ON lo.lo_suppkey = s.s_suppkey
WHERE cast(od.d_date AS date) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
GROUP BY od.d_year, c.c_mktsegment, p.p_category, s.s_region
ORDER BY total_revenue DESC
LIMIT 20
