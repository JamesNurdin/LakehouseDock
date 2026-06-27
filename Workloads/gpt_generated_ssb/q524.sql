WITH yearly_sales AS (
    SELECT
        d.d_year,
        c.c_region AS customer_region,
        s.s_region AS supplier_region,
        p.p_category,
        SUM(lo.lo_extendedprice * (1 - lo.lo_discount / 100.0)) AS total_revenue,
        SUM(lo.lo_extendedprice * (1 - lo.lo_discount / 100.0) - lo.lo_supplycost) AS total_profit,
        AVG(lo.lo_discount) AS avg_discount,
        COUNT(DISTINCT lo.lo_orderkey) AS order_count
    FROM lineorder lo
    JOIN dim_date d
        ON lo.lo_orderdate = CAST(d.d_datekey AS INTEGER)
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE CAST(d.d_date AS DATE) BETWEEN DATE '1993-01-01' AND DATE '1997-12-31'
      AND p.p_category IN ('MFGR#1', 'MFGR#2')
    GROUP BY d.d_year, c.c_region, s.s_region, p.p_category
)
SELECT
    d_year,
    customer_region,
    supplier_region,
    p_category,
    total_revenue,
    total_profit,
    avg_discount,
    order_count,
    total_revenue / NULLIF(total_profit, 0) AS revenue_to_profit_ratio
FROM yearly_sales
ORDER BY d_year, total_revenue DESC
LIMIT 50
