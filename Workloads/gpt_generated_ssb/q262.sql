WITH order_agg AS (
    SELECT
        c.c_region,
        c.c_mktsegment,
        d_order.d_year,
        p.p_category,
        SUM(lo.lo_extendedprice * (1 - lo.lo_discount / 100.0)) AS total_revenue,
        SUM(lo.lo_supplycost) AS total_supply_cost,
        SUM(lo.lo_quantity) AS total_quantity,
        AVG(lo.lo_discount) AS avg_discount
    FROM lineorder lo
    JOIN dim_date d_order
        ON CAST(lo.lo_orderdate AS VARCHAR) = d_order.d_datekey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE p.p_category = 'MFGR#12'
      AND d_order.d_year = '1995'
      AND s.s_region = 'ASIA'
    GROUP BY c.c_region, c.c_mktsegment, d_order.d_year, p.p_category
)
SELECT
    c_region,
    c_mktsegment,
    d_year,
    p_category,
    total_revenue,
    total_supply_cost,
    total_quantity,
    avg_discount,
    ROW_NUMBER() OVER (PARTITION BY c_region ORDER BY total_revenue DESC) AS region_revenue_rank
FROM order_agg
ORDER BY total_revenue DESC
LIMIT 10
