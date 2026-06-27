WITH revenue_by_region_year_category AS (
    SELECT
        c.c_region,
        d.d_year,
        p.p_category,
        SUM(lo.lo_extendedprice * (1 - lo.lo_discount / 100.0)) AS revenue,
        AVG(lo.lo_quantity) AS avg_quantity,
        COUNT(DISTINCT lo.lo_orderkey) AS order_cnt
    FROM lineorder lo
    JOIN dim_date d
        ON CAST(lo.lo_orderdate AS varchar) = d.d_datekey
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE c.c_region = 'ASIA'
      AND d.d_year BETWEEN '1992' AND '1997'
    GROUP BY c.c_region, d.d_year, p.p_category
)
SELECT
    c_region,
    d_year,
    p_category,
    revenue,
    avg_quantity,
    order_cnt,
    RANK() OVER (ORDER BY revenue DESC) AS revenue_rank
FROM revenue_by_region_year_category
ORDER BY revenue DESC
LIMIT 10
