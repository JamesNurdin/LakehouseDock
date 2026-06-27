WITH yearly_rev AS (
    SELECT
        d.d_year,
        s.s_region AS supplier_region,
        p.p_category,
        SUM(lo.lo_revenue) AS revenue,
        SUM(lo.lo_revenue - lo.lo_supplycost) AS profit
    FROM lineorder lo
    JOIN dim_date d
        ON lo.lo_orderdate = CAST(d.d_datekey AS INTEGER)   -- valid join rule: lineorder.lo_orderdate = dim_date.d_datekey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey                     -- valid join rule: lineorder.lo_suppkey = supplier.s_suppkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey                     -- valid join rule: lineorder.lo_partkey = part.p_partkey
    GROUP BY d.d_year, s.s_region, p.p_category
),
total_rev AS (
    SELECT
        d_year,
        supplier_region,
        SUM(revenue) AS total_revenue
    FROM yearly_rev
    GROUP BY d_year, supplier_region
)
SELECT
    yr.d_year,
    yr.supplier_region,
    yr.p_category,
    yr.revenue,
    yr.profit,
    CAST(yr.revenue AS DOUBLE) / tr.total_revenue * 100 AS revenue_pct
FROM yearly_rev yr
JOIN total_rev tr
    ON yr.d_year = tr.d_year
   AND yr.supplier_region = tr.supplier_region
ORDER BY yr.d_year, yr.supplier_region, yr.revenue DESC
LIMIT 100
