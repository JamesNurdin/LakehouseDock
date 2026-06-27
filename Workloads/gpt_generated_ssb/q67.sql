WITH lo_metrics AS (
    SELECT
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_supplycost,
        lo.lo_extendedprice * (1 - lo.lo_discount / 100.0) AS revenue,
        lo.lo_extendedprice * (1 - lo.lo_discount / 100.0) - lo.lo_supplycost * lo.lo_quantity AS profit
    FROM lineorder lo
)
SELECT
    s.s_region,
    p.p_category,
    od.d_year AS order_year,
    sum(m.revenue) AS total_revenue,
    sum(m.profit) AS total_profit,
    sum(m.lo_quantity) AS total_quantity,
    avg(m.lo_discount) AS avg_discount
FROM lo_metrics m
JOIN dim_date od ON CAST(od.d_datekey AS INTEGER) = m.lo_orderdate
JOIN dim_date cd ON CAST(cd.d_datekey AS INTEGER) = m.lo_commitdate
JOIN part p ON m.lo_partkey = p.p_partkey
JOIN supplier s ON m.lo_suppkey = s.s_suppkey
JOIN customer c ON m.lo_custkey = c.c_custkey
WHERE od.d_year = '1995'
  AND cd.d_date > od.d_date
  AND c.c_region = 'AMERICA'
GROUP BY s.s_region, p.p_category, od.d_year
ORDER BY total_profit DESC
LIMIT 100
