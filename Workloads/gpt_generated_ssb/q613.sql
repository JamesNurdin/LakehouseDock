WITH order_profit AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        (lo.lo_revenue - lo.lo_supplycost - lo.lo_tax) AS profit
    FROM lineorder lo
)
SELECT
    d.d_year,
    s.s_region,
    p.p_category,
    SUM(op.profit) AS total_profit,
    AVG(op.profit) AS avg_profit,
    COUNT(DISTINCT op.lo_custkey) AS distinct_customers
FROM order_profit op
JOIN dim_date d ON CAST(d.d_datekey AS INTEGER) = op.lo_orderdate
JOIN supplier s ON op.lo_suppkey = s.s_suppkey
JOIN part p ON op.lo_partkey = p.p_partkey
WHERE d.d_year = '1995'
GROUP BY d.d_year, s.s_region, p.p_category
ORDER BY total_profit DESC
LIMIT 10
