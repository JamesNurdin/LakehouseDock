WITH monthly_sales AS (
    SELECT
        od.d_year,
        od.d_month,
        s.s_region AS supplier_region,
        p.p_category AS part_category,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_supplycost) AS total_supplycost,
        SUM(lo.lo_revenue) - SUM(lo.lo_supplycost) AS profit,
        COUNT(DISTINCT lo.lo_orderkey) AS order_count
    FROM lineorder lo
    JOIN dim_date od
        ON lo.lo_orderdate = CAST(od.d_datekey AS integer)
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    WHERE CAST(od.d_date AS date) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
    GROUP BY od.d_year, od.d_month, s.s_region, p.p_category
),
ranked_sales AS (
    SELECT
        d_year,
        d_month,
        supplier_region,
        part_category,
        total_revenue,
        total_supplycost,
        profit,
        order_count,
        ROW_NUMBER() OVER (PARTITION BY d_year, d_month ORDER BY profit DESC) AS rank_by_profit
    FROM monthly_sales
)
SELECT
    d_year,
    d_month,
    supplier_region,
    part_category,
    total_revenue,
    total_supplycost,
    profit,
    order_count
FROM ranked_sales
WHERE rank_by_profit <= 3
ORDER BY d_year, d_month, rank_by_profit
