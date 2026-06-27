WITH revenue_by_supplier_month AS (
    SELECT
        s.s_region,
        d.d_year,
        d.d_month,
        SUM(lo.lo_revenue) AS total_revenue,
        AVG(lo.lo_discount) AS avg_discount,
        COUNT(*) AS order_cnt
    FROM lineorder lo
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN dim_date d
        ON CAST(d.d_datekey AS INTEGER) = lo.lo_orderdate
    WHERE p.p_category = 'MFGR#1'
      AND CAST(d.d_date AS DATE) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
    GROUP BY s.s_region, d.d_year, d.d_month
)
SELECT
    s_region,
    d_year,
    d_month,
    total_revenue,
    avg_discount,
    order_cnt,
    total_revenue / order_cnt AS avg_revenue_per_order
FROM revenue_by_supplier_month
ORDER BY total_revenue DESC
LIMIT 20
