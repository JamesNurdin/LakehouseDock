WITH aggregated AS (
    SELECT
        d.d_year,
        p.p_category,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_supplycost) AS total_supplycost,
        SUM(lo.lo_revenue - lo.lo_supplycost) AS profit
    FROM lineorder lo
    JOIN dim_date d
        ON CAST(d.d_datekey AS INTEGER) = lo.lo_orderdate
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    WHERE d.d_year IN ('1994', '1995')
    GROUP BY d.d_year, p.p_category
    HAVING SUM(lo.lo_revenue - lo.lo_supplycost) > 0
)
SELECT
    d_year,
    p_category,
    total_revenue,
    total_supplycost,
    profit,
    RANK() OVER (PARTITION BY d_year ORDER BY profit DESC) AS profit_rank
FROM aggregated
ORDER BY d_year, profit_rank
