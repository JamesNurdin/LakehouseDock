WITH revenue_by_category AS (
    SELECT
        c.c_region,
        od.d_year AS od_year,
        p.p_category,
        SUM(lo.lo_revenue) AS total_revenue,
        AVG(lo.lo_discount) AS avg_discount,
        COUNT(DISTINCT lo.lo_orderkey) AS order_count
    FROM lineorder lo
    JOIN dim_date od
        ON CAST(od.d_datekey AS integer) = lo.lo_orderdate
    JOIN dim_date cd
        ON CAST(cd.d_datekey AS integer) = lo.lo_commitdate
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE od.d_year = '1995'
      AND cd.d_holidayfl = 'N'
    GROUP BY
        c.c_region,
        od.d_year,
        p.p_category
    HAVING SUM(lo.lo_revenue) > 1000000
)
SELECT
    c_region,
    od_year,
    p_category,
    total_revenue,
    avg_discount,
    order_count,
    RANK() OVER (PARTITION BY c_region, od_year ORDER BY total_revenue DESC) AS revenue_rank
FROM revenue_by_category
ORDER BY total_revenue DESC
LIMIT 20
