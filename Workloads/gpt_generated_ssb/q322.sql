WITH revenue_by_category AS (
    SELECT
        cu.c_region,
        od.d_year,
        od.d_month,
        p.p_category,
        SUM(lo.lo_revenue) AS cat_revenue,
        SUM(lo.lo_supplycost) AS cat_supplycost,
        SUM(lo.lo_revenue - lo.lo_supplycost) AS cat_profit,
        AVG(lo.lo_discount) AS cat_avg_discount
    FROM lineorder lo
    JOIN dim_date od
        ON lo.lo_orderdate = CAST(od.d_datekey AS INTEGER)
    JOIN customer cu
        ON lo.lo_custkey = cu.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    WHERE od.d_year BETWEEN '1992' AND '1997'
    GROUP BY cu.c_region, od.d_year, od.d_month, p.p_category
),
ranked_category AS (
    SELECT
        c_region,
        d_year,
        d_month,
        p_category,
        cat_revenue,
        cat_supplycost,
        cat_profit,
        cat_avg_discount,
        ROW_NUMBER() OVER (PARTITION BY c_region, d_year, d_month ORDER BY cat_revenue DESC) AS revenue_rank
    FROM revenue_by_category
)
SELECT
    c_region,
    d_year,
    d_month,
    p_category,
    cat_revenue,
    cat_supplycost,
    cat_profit,
    cat_avg_discount,
    revenue_rank
FROM ranked_category
WHERE revenue_rank <= 3
ORDER BY c_region, d_year, d_month, revenue_rank
