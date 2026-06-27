WITH customer_revenue AS (
    SELECT
        c.c_custkey,
        c.c_name,
        c.c_region,
        c.c_nation,
        c.c_mktsegment,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_supplycost) AS total_supplycost,
        COUNT(DISTINCT lo.lo_orderkey) AS order_cnt,
        AVG(lo.lo_discount) AS avg_discount
    FROM lineorder lo
    JOIN customer c
      ON lo.lo_custkey = c.c_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_region, c.c_nation, c.c_mktsegment
),
ranked_customers AS (
    SELECT
        cr.c_custkey,
        cr.c_name,
        cr.c_region,
        cr.c_nation,
        cr.c_mktsegment,
        cr.total_revenue,
        cr.total_supplycost,
        cr.order_cnt,
        cr.avg_discount,
        RANK() OVER (PARTITION BY cr.c_region ORDER BY cr.total_revenue DESC) AS revenue_rank
    FROM customer_revenue cr
)
SELECT
    rc.c_region,
    rc.c_nation,
    rc.c_mktsegment,
    rc.c_name,
    rc.total_revenue,
    rc.total_supplycost,
    rc.total_revenue - rc.total_supplycost AS profit,
    rc.order_cnt,
    rc.avg_discount
FROM ranked_customers rc
WHERE rc.revenue_rank = 1
ORDER BY rc.c_region
