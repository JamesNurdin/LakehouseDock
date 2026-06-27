WITH order_dates AS (
    SELECT
        CAST(d_datekey AS INTEGER) AS d_datekey_int,
        d_year
    FROM dim_date
    WHERE d_year = '1995'
),
filtered_orders AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        lo.lo_quantity
    FROM lineorder lo
    JOIN order_dates od ON lo.lo_orderdate = od.d_datekey_int
)
SELECT
    s.s_region,
    p.p_category,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_supplycost) AS total_supplycost,
    SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
    COUNT(DISTINCT lo.lo_orderkey) AS order_count,
    AVG(lo.lo_discount) AS avg_discount
FROM filtered_orders lo
JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
JOIN part p ON lo.lo_partkey = p.p_partkey
GROUP BY s.s_region, p.p_category
ORDER BY total_profit DESC
LIMIT 10
