WITH revenue_by_category AS (
    SELECT
        d.d_year AS d_year,
        c.c_region AS c_region,
        s.s_region AS s_region,
        p.p_category AS p_category,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
        AVG(lo.lo_discount) AS avg_discount,
        SUM(lo.lo_quantity) AS total_quantity
    FROM lineorder lo
    JOIN dim_date d
        ON CAST(lo.lo_orderdate AS varchar) = d.d_datekey
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE d.d_date BETWEEN '1994-01-01' AND '1994-12-31'
    GROUP BY d.d_year, c.c_region, s.s_region, p.p_category
),
ranked_categories AS (
    SELECT
        d_year,
        c_region,
        s_region,
        p_category,
        total_revenue,
        total_profit,
        avg_discount,
        total_quantity,
        ROW_NUMBER() OVER (PARTITION BY d_year, c_region, s_region ORDER BY total_revenue DESC) AS revenue_rank
    FROM revenue_by_category
)
SELECT
    d_year,
    c_region,
    s_region,
    p_category,
    total_revenue,
    total_profit,
    avg_discount,
    total_quantity
FROM ranked_categories
WHERE revenue_rank <= 3
ORDER BY d_year, c_region, s_region, revenue_rank
