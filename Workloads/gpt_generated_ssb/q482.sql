WITH agg AS (
    SELECT
        od.d_year AS order_year,
        s.s_region AS supplier_region,
        p.p_category AS part_category,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_quantity) AS total_quantity,
        AVG(lo.lo_discount) AS avg_discount,
        COUNT(DISTINCT c.c_custkey) AS distinct_customers,
        COUNT(*) AS order_count
    FROM lineorder lo
    JOIN dim_date od
        ON CAST(lo.lo_orderdate AS VARCHAR) = od.d_datekey
    JOIN dim_date cd
        ON CAST(lo.lo_commitdate AS VARCHAR) = cd.d_datekey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    WHERE od.d_year BETWEEN '1995' AND '1997'
      AND cd.d_monthnuminyear = '12'
    GROUP BY od.d_year, s.s_region, p.p_category
),
ranked AS (
    SELECT
        order_year,
        supplier_region,
        part_category,
        total_revenue,
        total_quantity,
        avg_discount,
        distinct_customers,
        order_count,
        ROW_NUMBER() OVER (PARTITION BY order_year, supplier_region ORDER BY total_revenue DESC) AS revenue_rank
    FROM agg
)
SELECT
    order_year,
    supplier_region,
    part_category,
    total_revenue,
    total_quantity,
    avg_discount,
    distinct_customers,
    order_count,
    revenue_rank
FROM ranked
WHERE revenue_rank <= 3
ORDER BY order_year, supplier_region, revenue_rank
