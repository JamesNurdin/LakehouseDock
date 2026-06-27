WITH order_dates AS (
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
        d.d_year
    FROM lineorder lo
    JOIN dim_date d ON lo.lo_orderdate = CAST(d.d_datekey AS integer)
    WHERE d.d_year = '1993'
),
filtered_parts AS (
    SELECT p.p_partkey, p.p_category, p.p_brand1, p.p_color
    FROM part p
    WHERE p.p_category = 'MFGR#12'
)
SELECT
    c.c_region,
    od.d_year,
    SUM(od.lo_revenue) AS total_revenue,
    SUM(od.lo_revenue - od.lo_supplycost) AS total_profit,
    COUNT(DISTINCT od.lo_orderkey) AS order_count,
    AVG(od.lo_discount) AS avg_discount
FROM order_dates od
JOIN filtered_parts fp ON od.lo_partkey = fp.p_partkey
JOIN customer c ON od.lo_custkey = c.c_custkey
JOIN supplier s ON od.lo_suppkey = s.s_suppkey
GROUP BY c.c_region, od.d_year
ORDER BY total_revenue DESC
LIMIT 10
