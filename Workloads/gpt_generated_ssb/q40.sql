WITH order_data AS (
    SELECT
        lo.lo_orderdate,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_extendedprice,
        lo.lo_quantity,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        d.d_year,
        c.c_region,
        p.p_category,
        s.s_nation
    FROM lineorder lo
    JOIN dim_date d ON CAST(lo.lo_orderdate AS VARCHAR) = d.d_datekey
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    JOIN part p ON lo.lo_partkey = p.p_partkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    WHERE d.d_year BETWEEN '1992' AND '1997'
)
SELECT
    d_year,
    c_region,
    p_category,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    AVG(lo_discount) AS avg_discount,
    COUNT(*) AS order_cnt,
    SUM(lo_revenue) * 100.0 / SUM(SUM(lo_revenue)) OVER (PARTITION BY d_year) AS revenue_pct_by_region
FROM order_data
GROUP BY d_year, c_region, p_category
ORDER BY total_revenue DESC
LIMIT 100
