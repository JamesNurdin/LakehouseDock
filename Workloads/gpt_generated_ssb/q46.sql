WITH base_orders AS (
    SELECT
        lo_orderkey,
        lo_custkey,
        lo_partkey,
        lo_suppkey,
        lo_orderdate,
        lo_commitdate,
        lo_extendedprice,
        lo_discount,
        lo_revenue,
        lo_supplycost,
        lo_quantity
    FROM lineorder
)
SELECT
    c.c_region,
    p.p_category,
    d_o.d_year,
    SUM(o.lo_revenue) AS total_revenue,
    SUM(o.lo_revenue - o.lo_supplycost) AS total_profit,
    SUM(o.lo_extendedprice) AS total_extendedprice,
    SUM(o.lo_quantity) AS total_quantity,
    AVG(o.lo_discount) AS avg_discount,
    AVG(date_diff('day', CAST(d_o.d_date AS date), CAST(d_c.d_date AS date))) AS avg_lead_days
FROM base_orders o
JOIN dim_date d_o ON CAST(d_o.d_datekey AS integer) = o.lo_orderdate
JOIN dim_date d_c ON CAST(d_c.d_datekey AS integer) = o.lo_commitdate
JOIN customer c ON o.lo_custkey = c.c_custkey
JOIN part p ON o.lo_partkey = p.p_partkey
JOIN supplier s ON o.lo_suppkey = s.s_suppkey
WHERE d_o.d_year = '1995'
GROUP BY c.c_region, p.p_category, d_o.d_year
ORDER BY total_profit DESC
LIMIT 50
