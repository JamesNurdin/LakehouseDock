WITH revenue_by_category AS (
    SELECT
        d.d_year,
        c.c_region AS customer_region,
        s.s_region AS supplier_region,
        p.p_category,
        SUM(l.lo_revenue) AS total_revenue,
        SUM(l.lo_supplycost) AS total_supplycost,
        SUM(l.lo_revenue - l.lo_supplycost) AS profit
    FROM lineorder AS l
    JOIN dim_date AS d
        ON CAST(l.lo_orderdate AS VARCHAR) = d.d_datekey
    JOIN customer AS c
        ON l.lo_custkey = c.c_custkey
    JOIN part AS p
        ON l.lo_partkey = p.p_partkey
    JOIN supplier AS s
        ON l.lo_suppkey = s.s_suppkey
    WHERE d.d_year = '1995'
    GROUP BY d.d_year, c.c_region, s.s_region, p.p_category
)
SELECT
    r.d_year,
    r.customer_region,
    r.supplier_region,
    r.p_category,
    r.total_revenue,
    r.total_supplycost,
    r.profit,
    ROW_NUMBER() OVER (PARTITION BY r.customer_region ORDER BY r.total_revenue DESC) AS revenue_rank_by_customer_region
FROM revenue_by_category AS r
ORDER BY r.total_revenue DESC
LIMIT 20
