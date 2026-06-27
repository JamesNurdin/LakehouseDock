WITH filtered_orders AS (
    SELECT lo_orderkey,
           lo_custkey,
           lo_partkey,
           lo_suppkey,
           lo_orderdate,
           lo_revenue,
           lo_supplycost
    FROM lineorder
    WHERE lo_revenue > 0
),
orders_with_date AS (
    SELECT fo.lo_orderkey,
           fo.lo_custkey,
           fo.lo_partkey,
           fo.lo_suppkey,
           fo.lo_revenue,
           fo.lo_supplycost,
           od.d_year,
           od.d_date
    FROM filtered_orders fo
    JOIN dim_date od
        ON CAST(fo.lo_orderdate AS varchar) = od.d_datekey
    WHERE od.d_date BETWEEN '1995-01-01' AND '1995-12-31'
)
SELECT c.c_region,
       od.d_year,
       SUM(od.lo_revenue) AS total_revenue,
       SUM(od.lo_revenue - od.lo_supplycost) AS total_profit,
       AVG(od.lo_revenue) AS avg_revenue
FROM orders_with_date od
JOIN customer c
    ON od.lo_custkey = c.c_custkey
JOIN part p
    ON od.lo_partkey = p.p_partkey
WHERE p.p_category = 'MFGR#12'
GROUP BY c.c_region, od.d_year
ORDER BY total_revenue DESC
LIMIT 100
