WITH order_dates AS (
    SELECT
        CAST(d_datekey AS integer) AS date_key,
        d_year,
        d_date
    FROM dim_date
    WHERE d_year BETWEEN '1995' AND '1997'
)
SELECT
    od.d_year AS order_year,
    p.p_category,
    s.s_region AS supplier_region,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_supplycost) AS total_supplycost,
    SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
    SUM(lo.lo_quantity) AS total_quantity,
    AVG(lo.lo_discount) AS avg_discount
FROM lineorder lo
JOIN order_dates od ON lo.lo_orderdate = od.date_key
JOIN part p ON lo.lo_partkey = p.p_partkey
JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
GROUP BY od.d_year, p.p_category, s.s_region
ORDER BY od.d_year, total_profit DESC
LIMIT 20
