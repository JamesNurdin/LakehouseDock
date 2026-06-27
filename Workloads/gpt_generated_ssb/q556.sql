WITH order_data AS (
    SELECT
        CAST(lo.lo_orderdate AS VARCHAR) AS order_date_key,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey
    FROM lineorder lo
)
SELECT
    d.d_year AS year,
    c.c_region AS region,
    p.p_category AS category,
    SUM(od.lo_revenue) AS total_revenue,
    SUM(od.lo_supplycost) AS total_supply_cost,
    SUM(od.lo_revenue) - SUM(od.lo_supplycost) AS profit,
    AVG(od.lo_discount) AS avg_discount,
    COUNT(DISTINCT od.lo_orderkey) AS order_count
FROM order_data od
JOIN dim_date d
    ON od.order_date_key = d.d_datekey
JOIN customer c
    ON od.lo_custkey = c.c_custkey
JOIN part p
    ON od.lo_partkey = p.p_partkey
JOIN supplier s
    ON od.lo_suppkey = s.s_suppkey
WHERE d.d_year BETWEEN '1993' AND '1997'
GROUP BY d.d_year, c.c_region, p.p_category
ORDER BY d.d_year, c.c_region, p.p_category
