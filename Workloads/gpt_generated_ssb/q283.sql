WITH revenue_by_year_region_category AS (
    SELECT
        d.d_year,
        s.s_region,
        p.p_category,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_supplycost) AS total_supply_cost,
        AVG(lo.lo_discount) AS avg_discount,
        COUNT(DISTINCT lo.lo_orderkey) AS num_orders
    FROM lineorder lo
    JOIN dim_date d
        ON lo.lo_orderdate = CAST(d.d_datekey AS INTEGER)
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    WHERE CAST(d.d_date AS DATE) BETWEEN DATE '1994-01-01' AND DATE '1995-12-31'
    GROUP BY d.d_year, s.s_region, p.p_category
)
SELECT
    d_year,
    s_region,
    p_category,
    total_revenue,
    total_supply_cost,
    avg_discount,
    num_orders
FROM revenue_by_year_region_category
ORDER BY total_revenue DESC
LIMIT 10
