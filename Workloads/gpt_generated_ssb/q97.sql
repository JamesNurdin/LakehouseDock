WITH revenue_by_category AS (
    SELECT
        od.d_year AS year,
        c.c_region AS region,
        p.p_category AS category,
        sum(lo.lo_revenue) AS total_revenue,
        sum(lo.lo_supplycost) AS total_supply_cost,
        sum(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
        avg(lo.lo_discount) AS avg_discount,
        count(distinct lo.lo_orderkey) AS order_count
    FROM lineorder lo
    JOIN dim_date od ON CAST(lo.lo_orderdate AS VARCHAR) = od.d_datekey
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    JOIN part p ON lo.lo_partkey = p.p_partkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    WHERE CAST(od.d_date AS DATE) BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
      AND c.c_region = 'ASIA'
      AND p.p_category = 'MFGR#12'
    GROUP BY od.d_year, c.c_region, p.p_category
)
SELECT
    year,
    region,
    category,
    total_revenue,
    total_supply_cost,
    total_profit,
    avg_discount,
    order_count,
    rank() OVER (PARTITION BY region ORDER BY total_revenue DESC) AS revenue_rank
FROM revenue_by_category
ORDER BY total_revenue DESC
