WITH order_data AS (
    SELECT
        dd.d_year,
        c.c_region,
        p.p_category,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount
    FROM lineorder lo
    JOIN dim_date dd
      ON CAST(lo.lo_orderdate AS varchar) = dd.d_datekey
    JOIN customer c
      ON lo.lo_custkey = c.c_custkey
    JOIN part p
      ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
      ON lo.lo_suppkey = s.s_suppkey
    WHERE dd.d_year = '1995'
      AND c.c_region = 'AMERICA'
      AND p.p_category = 'MFGR#12'
)
SELECT
    d_year,
    c_region,
    p_category,
    sum(lo_revenue) AS total_revenue,
    sum(lo_supplycost) AS total_supply_cost,
    sum(lo_revenue - lo_supplycost) AS total_profit,
    avg(lo_discount) AS avg_discount
FROM order_data
GROUP BY d_year, c_region, p_category
ORDER BY total_revenue DESC
