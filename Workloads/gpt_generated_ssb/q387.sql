WITH order_dates AS (
    SELECT
        d_datekey,
        d_year
    FROM dim_date
    WHERE CAST(d_date AS DATE) BETWEEN DATE '1992-01-01' AND DATE '1992-12-31'
)
SELECT
    od.d_year,
    c.c_region,
    s.s_region,
    p.p_category,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
    SUM(lo.lo_quantity) AS total_quantity,
    AVG(lo.lo_discount) AS avg_discount
FROM lineorder lo
JOIN order_dates od
    ON CAST(lo.lo_orderdate AS VARCHAR) = od.d_datekey
JOIN customer c
    ON lo.lo_custkey = c.c_custkey
JOIN supplier s
    ON lo.lo_suppkey = s.s_suppkey
JOIN part p
    ON lo.lo_partkey = p.p_partkey
GROUP BY od.d_year, c.c_region, s.s_region, p.p_category
ORDER BY total_revenue DESC
LIMIT 100
