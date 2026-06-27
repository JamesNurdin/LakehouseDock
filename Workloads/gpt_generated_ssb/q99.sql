WITH filtered_orders AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_orderdate,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        d.d_year,
        c.c_region,
        p.p_category
    FROM lineorder lo
    JOIN dim_date d
        ON CAST(d.d_datekey AS INTEGER) = lo.lo_orderdate
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE d.d_year = '1997'
      AND p.p_category = 'MFGR#12'
      AND s.s_region = 'ASIA'
),
agg AS (
    SELECT
        d_year,
        c_region,
        p_category,
        SUM(lo_revenue) AS total_revenue,
        SUM(lo_revenue - lo_supplycost) AS total_profit,
        AVG(lo_discount) AS avg_discount,
        COUNT(DISTINCT lo_orderkey) AS order_cnt,
        COUNT(DISTINCT lo_custkey) AS distinct_customers,
        COUNT(DISTINCT lo_partkey) AS distinct_parts,
        COUNT(DISTINCT lo_suppkey) AS distinct_suppliers
    FROM filtered_orders
    GROUP BY d_year, c_region, p_category
)
SELECT
    d_year,
    c_region,
    p_category,
    total_revenue,
    total_profit,
    avg_discount,
    order_cnt,
    distinct_customers,
    distinct_parts,
    distinct_suppliers,
    RANK() OVER (PARTITION BY d_year ORDER BY total_revenue DESC) AS revenue_rank
FROM agg
ORDER BY d_year, revenue_rank
LIMIT 20
