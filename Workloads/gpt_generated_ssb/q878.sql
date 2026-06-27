WITH filtered_orders AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        lo.lo_quantity,
        d.d_year,
        d.d_month
    FROM lineorder lo
    JOIN dim_date d
        ON lo.lo_orderdate = CAST(d.d_datekey AS INTEGER)
    WHERE d.d_year = '1995'
)
SELECT
    c.c_region,
    p.p_category,
    s.s_region,
    fo.d_month,
    COUNT(DISTINCT fo.lo_orderkey) AS order_count,
    SUM(fo.lo_revenue) AS total_revenue,
    SUM(fo.lo_supplycost) AS total_supply_cost,
    SUM(fo.lo_revenue - fo.lo_supplycost) AS total_profit,
    AVG(fo.lo_discount) AS avg_discount
FROM filtered_orders fo
JOIN customer c
    ON fo.lo_custkey = c.c_custkey
JOIN part p
    ON fo.lo_partkey = p.p_partkey
JOIN supplier s
    ON fo.lo_suppkey = s.s_suppkey
GROUP BY
    c.c_region,
    p.p_category,
    s.s_region,
    fo.d_month
HAVING SUM(fo.lo_revenue) > 1000000
ORDER BY total_revenue DESC
LIMIT 50
