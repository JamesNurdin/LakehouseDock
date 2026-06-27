WITH lo_fact AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_supplycost,
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_extendedprice * (1 - lo.lo_discount / 100.0) AS revenue,
        lo.lo_extendedprice * (1 - lo.lo_discount / 100.0) - lo.lo_supplycost AS profit
    FROM lineorder lo
)
SELECT
    c.c_region,
    p.p_category,
    d_order.d_year AS order_year,
    SUM(lo_fact.revenue) AS total_revenue,
    SUM(lo_fact.profit) AS total_profit,
    COUNT(DISTINCT lo_fact.lo_orderkey) AS num_orders
FROM lo_fact
JOIN dim_date d_order
    ON CAST(d_order.d_datekey AS INTEGER) = lo_fact.lo_orderdate
JOIN dim_date d_commit
    ON CAST(d_commit.d_datekey AS INTEGER) = lo_fact.lo_commitdate
JOIN customer c
    ON lo_fact.lo_custkey = c.c_custkey
JOIN part p
    ON lo_fact.lo_partkey = p.p_partkey
JOIN supplier s
    ON lo_fact.lo_suppkey = s.s_suppkey
WHERE d_order.d_year = '1995'
  AND c.c_region = 'ASIA'
GROUP BY c.c_region, p.p_category, d_order.d_year
ORDER BY total_profit DESC
LIMIT 10
