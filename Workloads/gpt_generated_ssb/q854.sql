WITH revenue_by_region_category AS (
    SELECT
        d_order.d_year AS order_year,
        c.c_region,
        p.p_category,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_supplycost) AS total_supplycost,
        AVG(lo.lo_discount) AS avg_discount,
        COUNT(DISTINCT lo.lo_orderkey) AS distinct_orders
    FROM lineorder lo
    JOIN dim_date d_order
        ON CAST(lo.lo_orderdate AS varchar) = d_order.d_datekey
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE
        p.p_category = 'MFGR#12'
        AND s.s_region = 'ASIA'
        AND d_order.d_year = '1997'
    GROUP BY
        d_order.d_year,
        c.c_region,
        p.p_category
)
SELECT
    r.order_year,
    r.c_region,
    r.p_category,
    r.total_revenue,
    r.total_supplycost,
    r.avg_discount,
    r.distinct_orders,
    RANK() OVER (PARTITION BY r.c_region ORDER BY r.total_revenue DESC) AS region_category_rank
FROM revenue_by_region_category r
ORDER BY r.c_region, region_category_rank
LIMIT 100
