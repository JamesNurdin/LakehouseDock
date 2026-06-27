WITH order_agg AS (
    SELECT
        d.d_year,
        c.c_region,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_supplycost) AS total_supply_cost,
        SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
        COUNT(DISTINCT lo.lo_orderkey) AS num_orders,
        AVG(lo.lo_discount) AS avg_discount
    FROM lineorder lo
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    JOIN dim_date d
        ON lo.lo_orderdate = CAST(d.d_datekey AS integer)
    WHERE p.p_category = 'MFGR#12'
      AND s.s_region = 'ASIA'
      AND CAST(d.d_year AS integer) BETWEEN 1992 AND 1997
    GROUP BY d.d_year, c.c_region
)
SELECT
    d_year,
    c_region,
    total_revenue,
    total_profit,
    num_orders,
    avg_discount,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_revenue DESC) AS region_rank_in_year
FROM order_agg
ORDER BY d_year, region_rank_in_year
