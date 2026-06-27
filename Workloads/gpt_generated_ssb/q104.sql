-- Revenue and discount analysis by year, customer region, and product category
WITH revenue_by_category AS (
    SELECT
        d_order.d_year,
        c.c_region,
        p.p_category,
        SUM(lo.lo_revenue) AS category_revenue,
        AVG(lo.lo_discount) AS avg_discount,
        COUNT(DISTINCT lo.lo_orderkey) AS order_cnt
    FROM lineorder lo
    JOIN dim_date d_order
        ON CAST(d_order.d_datekey AS INTEGER) = lo.lo_orderdate
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE d_order.d_year IN ('1997', '1998')
    GROUP BY d_order.d_year, c.c_region, p.p_category
)
SELECT
    r.d_year,
    r.c_region,
    r.p_category,
    r.category_revenue,
    r.avg_discount,
    r.order_cnt,
    r.category_revenue / SUM(r.category_revenue) OVER (PARTITION BY r.d_year, r.c_region) AS revenue_share
FROM revenue_by_category r
ORDER BY r.category_revenue DESC
