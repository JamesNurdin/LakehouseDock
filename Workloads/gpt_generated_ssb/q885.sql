WITH order_info AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_quantity,
        d.d_year,
        c.c_mktsegment,
        p.p_category
    FROM lineorder lo
    JOIN dim_date d
        ON CAST(lo.lo_orderdate AS VARCHAR) = d.d_datekey
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE d.d_year BETWEEN '1995' AND '1997'
)
SELECT
    d_year,
    c_mktsegment,
    p_category,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    SUM(lo_quantity) AS total_quantity,
    COUNT(DISTINCT lo_orderkey) AS distinct_orders
FROM order_info
GROUP BY d_year, c_mktsegment, p_category
ORDER BY total_revenue DESC
LIMIT 100
