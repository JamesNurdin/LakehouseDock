WITH base_orders AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        od.d_year AS order_year,
        cd.d_year AS commit_year,
        c.c_mktsegment,
        s.s_region AS s_region,
        p.p_category AS p_category
    FROM lineorder lo
    JOIN dim_date od
        ON CAST(lo.lo_orderdate AS VARCHAR) = od.d_datekey
    JOIN dim_date cd
        ON CAST(lo.lo_commitdate AS VARCHAR) = cd.d_datekey
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    WHERE od.d_year = '1995'
      AND c.c_mktsegment = 'AUTOMOBILE'
      AND lo.lo_commitdate > lo.lo_orderdate
)
SELECT
    order_year,
    s_region,
    p_category,
    sum(lo_revenue) AS total_revenue,
    sum(lo_supplycost) AS total_supply_cost,
    sum(lo_revenue - lo_supplycost) AS total_profit
FROM base_orders
GROUP BY order_year, s_region, p_category
HAVING sum(lo_revenue) > 1000000
ORDER BY total_revenue DESC
