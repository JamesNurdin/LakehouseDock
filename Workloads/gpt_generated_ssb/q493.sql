SELECT
    od.d_year AS order_year,
    c.c_mktsegment,
    p.p_brand1,
    s.s_region,
    sum(lo.lo_revenue) AS total_revenue,
    sum(lo.lo_supplycost) AS total_supplycost,
    sum(lo.lo_revenue) - sum(lo.lo_supplycost) AS profit,
    (sum(lo.lo_revenue) - sum(lo.lo_supplycost)) / nullif(sum(lo.lo_revenue), 0) AS profit_margin,
    avg(lo.lo_discount) AS avg_discount,
    count(distinct lo.lo_orderkey) AS order_count
FROM lineorder lo
JOIN dim_date od ON cast(lo.lo_orderdate AS varchar) = od.d_datekey
JOIN dim_date cd ON cast(lo.lo_commitdate AS varchar) = cd.d_datekey
JOIN customer c ON lo.lo_custkey = c.c_custkey
JOIN part p ON lo.lo_partkey = p.p_partkey
JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
WHERE od.d_year = '1995'
  AND lo.lo_shipmode = 'AIR'
  AND cd.d_date >= od.d_date
GROUP BY od.d_year, c.c_mktsegment, p.p_brand1, s.s_region
ORDER BY profit DESC
LIMIT 10
