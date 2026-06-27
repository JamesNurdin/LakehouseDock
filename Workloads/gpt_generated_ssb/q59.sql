WITH order_agg AS (
    SELECT
        c.c_region AS cust_region,
        s.s_region AS supp_region,
        COUNT(*) AS order_cnt,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_supplycost) AS total_supplycost,
        AVG(lo.lo_discount) AS avg_discount
    FROM lineorder lo
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    WHERE c.c_mktsegment = 'BUILDING'
    GROUP BY c.c_region, s.s_region
)
SELECT
    cust_region,
    supp_region,
    order_cnt,
    total_revenue,
    total_supplycost,
    (total_revenue - total_supplycost) AS profit,
    avg_discount,
    RANK() OVER (ORDER BY (total_revenue - total_supplycost) DESC) AS profit_rank
FROM order_agg
ORDER BY profit DESC
