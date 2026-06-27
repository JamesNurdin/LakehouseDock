WITH order_dates AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_revenue,
        lo.lo_supplycost,
        d.d_year,
        d.d_month,
        d.d_date
    FROM lineorder lo
    JOIN dim_date d
        ON CAST(d.d_datekey AS integer) = lo.lo_orderdate
    WHERE d.d_date BETWEEN '1995-01-01' AND '1995-12-31'
),
profit_by_region_cat AS (
    SELECT
        od.d_year,
        od.d_month,
        s.s_region,
        p.p_category,
        SUM(od.lo_revenue - od.lo_supplycost) AS total_profit
    FROM order_dates od
    JOIN part p
        ON od.lo_partkey = p.p_partkey
    JOIN supplier s
        ON od.lo_suppkey = s.s_suppkey
    JOIN customer c
        ON od.lo_custkey = c.c_custkey
    GROUP BY od.d_year, od.d_month, s.s_region, p.p_category
),
ranked AS (
    SELECT
        d_year,
        d_month,
        s_region,
        p_category,
        total_profit,
        ROW_NUMBER() OVER (PARTITION BY d_year, d_month ORDER BY total_profit DESC) AS rn
    FROM profit_by_region_cat
)
SELECT
    d_year,
    d_month,
    s_region,
    p_category,
    total_profit
FROM ranked
WHERE rn <= 5
ORDER BY d_year, d_month, total_profit DESC
