WITH revenue_by_year AS (
    SELECT
        c.c_region AS region,
        s.s_nation AS supplier_nation,
        p.p_category AS category,
        d.d_year AS order_year,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_quantity) AS total_quantity,
        AVG(lo.lo_discount) AS avg_discount
    FROM lineorder lo
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN dim_date d
        ON CAST(d.d_datekey AS INTEGER) = lo.lo_orderdate
    WHERE d.d_year BETWEEN '1993' AND '1997'
    GROUP BY c.c_region, s.s_nation, p.p_category, d.d_year
)
SELECT
    region,
    supplier_nation,
    category,
    order_year,
    total_revenue,
    total_quantity,
    avg_discount,
    LAG(total_revenue) OVER (PARTITION BY region, supplier_nation, category ORDER BY order_year) AS prev_year_revenue,
    CASE
        WHEN LAG(total_revenue) OVER (PARTITION BY region, supplier_nation, category ORDER BY order_year) IS NULL THEN NULL
        ELSE (total_revenue - LAG(total_revenue) OVER (PARTITION BY region, supplier_nation, category ORDER BY order_year))
             / LAG(total_revenue) OVER (PARTITION BY region, supplier_nation, category ORDER BY order_year) * 100.0
    END AS revenue_growth_pct
FROM revenue_by_year
ORDER BY region, supplier_nation, category, order_year
