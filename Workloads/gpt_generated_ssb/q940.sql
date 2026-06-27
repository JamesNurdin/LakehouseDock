WITH agg AS (
    SELECT
        s.s_region AS supp_region,
        c.c_region AS cust_region,
        d.d_year,
        d.d_month,
        p.p_category,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_supplycost) AS total_supply_cost,
        SUM(lo.lo_extendedprice) AS total_extended_price,
        AVG(lo.lo_discount) AS avg_discount,
        COUNT(DISTINCT lo.lo_orderkey) AS order_count
    FROM lineorder lo
    JOIN dim_date d
        ON CAST(lo.lo_orderdate AS VARCHAR) = d.d_datekey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    WHERE d.d_year = '1994'
      AND p.p_category = 'MFGR#12'
      AND c.c_region = 'ASIA'
    GROUP BY s.s_region, c.c_region, d.d_year, d.d_month, p.p_category
)
SELECT
    supp_region,
    cust_region,
    d_year,
    d_month,
    p_category,
    total_revenue,
    total_supply_cost,
    total_extended_price,
    avg_discount,
    order_count,
    ROW_NUMBER() OVER (PARTITION BY d_year, d_month ORDER BY total_revenue DESC) AS revenue_rank
FROM agg
ORDER BY d_year, d_month, revenue_rank
LIMIT 20
