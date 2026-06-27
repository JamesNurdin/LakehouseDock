WITH agg AS (
    SELECT
        d.d_year AS year,
        c.c_region AS region,
        p.p_category AS category,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_supplycost) AS total_supply_cost,
        SUM(lo.lo_quantity) AS total_quantity,
        AVG(lo.lo_discount) AS avg_discount
    FROM lineorder lo
    JOIN dim_date d ON lo.lo_orderdate = CAST(d.d_datekey AS integer)
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    JOIN part p ON lo.lo_partkey = p.p_partkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    WHERE lo.lo_shipmode = 'AIR'
      AND CAST(d.d_date AS date) BETWEEN DATE '1995-01-01' AND DATE '1996-12-31'
    GROUP BY d.d_year, c.c_region, p.p_category
)
SELECT
    year,
    region,
    category,
    total_revenue,
    total_supply_cost,
    total_quantity,
    avg_discount,
    RANK() OVER (PARTITION BY year, region ORDER BY total_revenue DESC) AS revenue_rank
FROM agg
ORDER BY year, region, revenue_rank
