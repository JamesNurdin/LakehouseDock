WITH order_dates AS (
    SELECT
        CAST(d_datekey AS integer) AS order_date_key,
        d_year,
        d_date
    FROM dim_date
    WHERE d_year = '1995'
)
SELECT
    od.d_year AS order_year,
    c.c_region AS customer_region,
    p.p_category AS part_category,
    s.s_region AS supplier_region,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit
FROM lineorder lo
JOIN order_dates od ON lo.lo_orderdate = od.order_date_key
JOIN customer c ON lo.lo_custkey = c.c_custkey
JOIN part p ON lo.lo_partkey = p.p_partkey
JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
WHERE
    p.p_category = 'MFGR#12'
    AND s.s_region = 'ASIA'
    AND lo.lo_shipmode = 'AIR'
GROUP BY
    od.d_year,
    c.c_region,
    p.p_category,
    s.s_region
ORDER BY total_revenue DESC
LIMIT 10
