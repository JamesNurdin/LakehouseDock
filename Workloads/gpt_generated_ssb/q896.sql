WITH order_data AS (
    SELECT
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_quantity,
        lo.lo_revenue,
        lo.lo_discount,
        lo.lo_supplycost,
        od.d_yearmonth,
        od.d_date
    FROM lineorder lo
    JOIN dim_date od
        ON CAST(lo.lo_orderdate AS VARCHAR) = od.d_datekey
    WHERE CAST(od.d_date AS DATE) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
)
SELECT
    s.s_region,
    p.p_category,
    od.d_yearmonth,
    SUM(od.lo_revenue) AS total_revenue,
    SUM(od.lo_quantity) AS total_quantity,
    AVG(od.lo_discount) AS avg_discount,
    SUM(od.lo_supplycost) AS total_supplycost
FROM order_data od
JOIN part p
    ON od.lo_partkey = p.p_partkey
JOIN supplier s
    ON od.lo_suppkey = s.s_suppkey
GROUP BY
    s.s_region,
    p.p_category,
    od.d_yearmonth
ORDER BY
    total_revenue DESC
LIMIT 100
