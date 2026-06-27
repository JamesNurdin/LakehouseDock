WITH base_orders AS (
    SELECT
        lo.lo_orderdate,
        lo.lo_custkey,
        lo.lo_suppkey,
        lo.lo_partkey,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        d.d_year,
        c.c_region AS c_region,
        s.s_region AS s_region,
        p.p_category
    FROM lineorder lo
    JOIN dim_date d
        ON lo.lo_orderdate = CAST(d.d_datekey AS integer)
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    WHERE d.d_year IN ('1993', '1994')
)
SELECT
    d_year,
    c_region,
    s_region,
    p_category,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_supplycost) AS total_supply_cost,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    AVG(lo_discount) AS avg_discount
FROM base_orders
GROUP BY d_year, c_region, s_region, p_category
ORDER BY total_revenue DESC
LIMIT 100
