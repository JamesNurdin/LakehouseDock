WITH agg AS (
    SELECT
        d.d_year,
        c.c_region,
        SUM(lo.lo_revenue) AS total_revenue,
        AVG(lo.lo_discount) AS avg_discount,
        COUNT(DISTINCT lo.lo_orderkey) AS order_count
    FROM lineorder lo
    JOIN dim_date d
        ON lo.lo_orderdate = CAST(d.d_datekey AS INTEGER)
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    WHERE p.p_category = 'MFGR#1'
      AND d.d_year BETWEEN '1995' AND '1997'
    GROUP BY d.d_year, c.c_region
)
SELECT
    d_year,
    c_region,
    total_revenue,
    avg_discount,
    order_count,
    RANK() OVER (PARTITION BY d_year ORDER BY total_revenue DESC) AS revenue_rank
FROM agg
ORDER BY d_year, revenue_rank
